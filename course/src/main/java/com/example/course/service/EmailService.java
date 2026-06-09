package com.example.course.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger log = LoggerFactory.getLogger(EmailService.class);
    private static final String DUMMY_USER = "dummy@dev.com";

    private final JavaMailSender mailSender;
    private final String smtpUser;

    public EmailService(JavaMailSender mailSender,
                        @Value("${spring.mail.username:dummy@dev.com}") String smtpUser) {
        this.mailSender = mailSender;
        this.smtpUser = smtpUser;
    }

    public void sendVerificationCode(String to, String code) {
        if (DUMMY_USER.equals(smtpUser)) {
            log.info("===== 验证码: {} (SMTP 未配置) =====", code);
            return;
        }
        SimpleMailMessage message = new SimpleMailMessage();
        message.setFrom(smtpUser);
        message.setTo(to);
        message.setSubject("教育助手 - 邮箱验证码");
        message.setText("您的验证码是：" + code + "，有效期 5 分钟。");
        mailSender.send(message);
        log.info("验证码已发送至 {}", to);
    }
}
