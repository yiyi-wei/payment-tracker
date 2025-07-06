/*
 * @Author: han.wei han.wei.work2023@gmail.com
 * @Date: 2025-07-03 21:56:45
 * @LastEditors: han.wei han.wei.work2023@gmail.com
 * @LastEditTime: 2025-07-05 12:33:33
 * @FilePath: /payment-tracker/payment-tracker-app/src/main/java/io/github/paymenttracker/app/PaymentTrackerApplication.java
 * @Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
 */
package io.github.paymenttracker.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.domain.EntityScan;
import org.springframework.context.annotation.ComponentScan;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;

@SpringBootApplication
@EnableJpaRepositories(basePackages = "io.github.paymenttracker")
@ComponentScan(basePackages = "io.github.paymenttracker")
@EntityScan(basePackages = "io.github.paymenttracker")
public class PaymentTrackerApplication {

    public static void main(String[] args) {
        SpringApplication.run(PaymentTrackerApplication.class, args);
    }

}