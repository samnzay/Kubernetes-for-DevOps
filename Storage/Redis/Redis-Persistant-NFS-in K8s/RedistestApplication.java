package com.redis.test.redistest;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;


@SpringBootApplication
@Configuration
@EnableCaching
public class RedistestApplication {

	public static void main(String[] args) {
		SpringApplication.run(RedistestApplication.class, args);
	}

}