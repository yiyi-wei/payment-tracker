<!--
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-02 16:04:59
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-02 16:05:05
 * @FilePath: /payment-tracker/memory-bank/productContext.md
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
-->
# Product Context

This file provides a high-level overview of the project and the expected product that will be created. Initially it is based upon projectBrief.md (if provided) and all other available project-related information in the working directory. This file is intended to be updated as the project evolves, and should be used to inform all other modes of the project's goals and context.
2025-07-02 16:04:42 - Log of updates made will be appended as footnotes to the end of this file.

*

## Project Goal

*   创建一个跨平台的支付记录跟踪工具，旨在帮助用户便捷地管理和监控他们的所有支付记录，提供多样化的数据分析，支持多种支付方式，保障支付信息的安全性和隐私性，且提供便捷的跨平台访问方式，预计支持Web端、Ios、Android等平台。

## Key Features

*   **用户管理**: 注册、登录、账户管理。
*   **支付记录追踪**: 自动同步、手动添加、图片上传AI解析、分类、详情查看。
*   **数据分析**: 消费趋势、支出分类、支付方式分析。
*   **提醒与通知**: 周期提醒、失败提醒。
*   **导出与分享**: 导出为Excel/CSV、分享为PDF。
*   **安全性**: 数据加密、二次验证。

## Overall Architecture

*   采用DDD、六边形架构和CQRS原则。
*   技术栈: Java 21, Spring Boot, Spring Data JPA, PostgreSQL, RocketMQ, LangChain4j。
*   多模块Maven项目。