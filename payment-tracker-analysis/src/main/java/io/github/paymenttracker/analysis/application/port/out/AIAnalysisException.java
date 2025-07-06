/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-06 12:31:12
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-06 12:31:14
 * @FilePath: /payment-tracker/payment-tracker-analysis/src/main/java/io/github/paymenttracker/analysis/application/port/out/AIAnalysisException.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.analysis.application.port.out;

/**
 * Custom exception for AI analysis failures.
 */
public class AIAnalysisException extends RuntimeException {
    public AIAnalysisException(String message, Throwable cause) {
        super(message, cause);
    }
}