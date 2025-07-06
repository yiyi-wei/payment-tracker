# AI支付结果识别核心流程伪代码

本文档基于 `doc/domain-puml/ai_analysis_context.puml` 和 `doc/sql/ai_analysis_context_init.sql`，为“AI支付结果识别”上下文的核心业务流程提供伪代码实现。

## 场景1: 处理图片上传请求

**组件**: `ImageAnalysisApplicationService`
**职责**: 接收图片上传命令，处理图片去重，将新图片存入对象存储，创建`PaymentImageAgg`聚合根并发布分析请求事件。

```plaintext
// 定义应用服务
CLASS ImageAnalysisApplicationService

    // 依赖注入
    PRIVATE paymentImageRepository: PaymentImageRepository
    PRIVATE storageService: StorageService
    PRIVATE eventPublisher: DomainEventPublisher

    // 处理图片上传命令的方法
    // command 包含: uploaderId, imageBytes, originalFileName
    FUNCTION handleImageUpload(command: UploadPaymentImageCommand): UUID

        // 1. 计算图片内容的SHA-256哈希值
        imageHash = calculateSHA256(command.imageBytes)

        // 2. 根据哈希值查询数据库，执行图片去重逻辑
        // 注意: 当前的 payment_images 表结构缺少 image_hash 字段，需要补充。
        existingImage = paymentImageRepository.findByHash(imageHash)

        IF existingImage IS NOT NULL THEN
            // 如果图片已存在，直接发布事件以重新触发分析流程
            // 这是一个可选择的策略，也可以直接返回错误或现有ID
            existingImage.requestAnalysis()
            eventPublisher.publish(existingImage.getDomainEvents())
            LOG "Duplicate image detected (hash: ${imageHash}). Re-triggering analysis for image ID: ${existingImage.id}"
            RETURN existingImage.id
        END IF

        // 3. 如果为新图片，则调用 StorageService 将其上传到阿里云OSS
        // storageService 会返回图片的公开访问URL
        imageUrl = storageService.upload(
            bucket = "payment-images",
            objectName = "${uploaderId}/${imageHash}-${originalFileName}",
            content = command.imageBytes
        )

        // 4. 创建 PaymentImageAgg 聚合根
        // 聚合根的工厂方法负责验证和初始化
        newPaymentImage = PaymentImageAgg.create(
            uploaderId = command.uploaderId,
            imageUrl = imageUrl,
            imageHash = imageHash // 将哈希值存入聚合根
        )

        // 持久化新的聚合根
        paymentImageRepository.save(newPaymentImage)

        // 5. 发布 ImageAnalysisRequestedEvent 事件
        // 聚合根内部生成事件，由应用服务发布
        eventPublisher.publish(newPaymentImage.getDomainEvents())
        LOG "New image saved (ID: ${newPaymentImage.id}). Analysis requested."

        RETURN newPaymentImage.id

    END FUNCTION

END CLASS
```

## 场景2: 处理AI分析请求 (事件监听器)

**组件**: `ImageAnalysisRequestListener` (领域事件监听器)
**职责**: 监听`ImageAnalysisRequestedEvent`，创建`ImageAnalysisAttemptAgg`聚合根，并异步调用`AIService`执行分析。

```plaintext
// 定义事件监听器
CLASS ImageAnalysisRequestListener

    // 依赖注入
    PRIVATE attemptRepository: ImageAnalysisAttemptRepository
    PRIVATE aiService: AIService

    // 监听 ImageAnalysisRequestedEvent
    @EventListener
    FUNCTION onImageAnalysisRequested(event: ImageAnalysisRequestedEvent)

        LOG "Received ImageAnalysisRequestedEvent for image ID: ${event.paymentImageId}"

        // 1. 创建 ImageAnalysisAttemptAgg 聚合根
        // 聚合根的初始状态为 PENDING_ANALYSIS
        newAttempt = ImageAnalysisAttemptAgg.create(
            paymentImageId = event.paymentImageId
        )
        attemptRepository.save(newAttempt)
        LOG "Created new ImageAnalysisAttemptAgg with ID: ${newAttempt.id}"

        // 2. 调用 @Async 的 AIService 方法来异步执行AI分析
        // 将新创建的 attemptId 和 imageUrl 传递给异步服务
        aiService.performAnalysis(
            attemptId = newAttempt.id,
            imageUrl = event.imageUrl
        )
        LOG "Asynchronously invoked AIService for attempt ID: ${newAttempt.id}"

    END FUNCTION

END CLASS

// 定义异步AI服务
CLASS AIService

    // 依赖注入
    PRIVATE aiProvider: ExternalAIProvider // 封装了如LangChain4j的调用
    PRIVATE mqProducer: MessageQueueProducer // 封装了RocketMQ的生产者

    // 异步执行方法
    @Async
    FUNCTION performAnalysis(attemptId: UUID, imageUrl: String)
        
        LOG "Starting AI analysis for attempt ID: ${attemptId}"
        
        // 在这里可以先更新Attempt状态为 ANALYZING
        // (这需要一个应用服务方法来执行)
        // imageAnalysisApplicationService.markAsAnalyzing(attemptId)

        TRY
            // 调用外部AI服务进行图片内容识别
            aiResult = aiProvider.analyzePaymentImage(imageUrl)

            // 分析成功，构建成功消息并发送到RocketMQ
            successMessage = createSuccessMessage(
                attemptId = attemptId,
                rawResult = aiResult.rawText,
                parsedDetails = aiResult.structuredData
            )
            mqProducer.send(
                topic = "AI_RESULT_TOPIC",
                message = successMessage
            )
            LOG "AI analysis succeeded for attempt ID: ${attemptId}. Sent success message to MQ."

        CATCH AIException as error
            // 分析失败，构建失败消息并发送到RocketMQ
            failureMessage = createFailureMessage(
                attemptId = attemptId,
                reason = error.message
            )
            mqProducer.send(
                topic = "AI_RESULT_TOPIC",
                message = failureMessage
            )
            LOG "AI analysis failed for attempt ID: ${attemptId}. Reason: ${error.message}. Sent failure message to MQ."
        END TRY

    END FUNCTION

END CLASS
```

## 场景3: 处理AI回调 (RocketMQ监听器)

**组件**: `AIResultListener` (消息队列消费者)
**职责**: 监听RocketMQ的`AI_RESULT_TOPIC`主题，根据收到的成功或失败消息，调用应用服务来更新`ImageAnalysisAttemptAgg`的状态。

```plaintext
// 定义RocketMQ消费者
@RocketMQMessageListener(topic = "AI_RESULT_TOPIC", consumerGroup = "payment-analysis-group")
CLASS AIResultListener

    // 依赖注入
    PRIVATE imageAnalysisApplicationService: ImageAnalysisApplicationService

    // 处理收到的消息
    FUNCTION onAIResultMessage(message: AIResultMessage)

        LOG "Received AI result message from MQ for attempt ID: ${message.attemptId}"

        IF message.isSuccess THEN
            // 如果是成功消息，调用应用服务处理成功逻辑
            successCommand = new RecordAnalysisSuccessCommand(
                attemptId = message.attemptId,
                rawResult = message.rawResult,
                parsedDetails = message.parsedDetails
            )
            imageAnalysisApplicationService.handleAnalysisSuccess(successCommand)
        ELSE
            // 如果是失败消息，调用应用服务处理失败逻辑
            failureCommand = new RecordAnalysisFailureCommand(
                attemptId = message.attemptId,
                failureReason = message.failureReason
            )
            imageAnalysisApplicationService.handleAnalysisFailure(failureCommand)
        END IF

    END FUNCTION

END CLASS


// 在 ImageAnalysisApplicationService 中添加处理回调的方法
CLASS ImageAnalysisApplicationService

    // ... (handleImageUpload 方法已定义) ...

    // 处理AI分析成功的回调
    FUNCTION handleAnalysisSuccess(command: RecordAnalysisSuccessCommand)
        attempt = attemptRepository.findById(command.attemptId)
        IF attempt IS NULL THEN
            LOG_ERROR "Attempt not found for ID: ${command.attemptId}"
            RETURN
        END IF

        // 调用聚合根方法记录成功结果
        attempt.recordSuccess(
            result = command.rawResult,
            details = command.parsedDetails
        )
        attemptRepository.save(attempt)
        eventPublisher.publish(attempt.getDomainEvents()) // 发布 ImageAnalysisSucceededEvent
        LOG "Successfully recorded AI analysis result for attempt ID: ${command.attemptId}"
    END FUNCTION

    // 处理AI分析失败的回调
    FUNCTION handleAnalysisFailure(command: RecordAnalysisFailureCommand)
        attempt = attemptRepository.findById(command.attemptId)
        IF attempt IS NULL THEN
            LOG_ERROR "Attempt not found for ID: ${command.attemptId}"
            RETURN
        END IF

        // 调用聚合根方法记录失败原因
        attempt.recordFailure(reason = command.failureReason)
        attemptRepository.save(attempt)
        eventPublisher.publish(attempt.getDomainEvents()) // 发布 ImageAnalysisFailedEvent
        LOG "Recorded AI analysis failure for attempt ID: ${command.attemptId}. Reason: ${command.failureReason}"
    END FUNCTION

END CLASS