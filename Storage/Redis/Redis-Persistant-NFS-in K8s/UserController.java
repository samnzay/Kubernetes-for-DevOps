package com.redis.test.redistest.controller;

import com.redis.test.redistest.model.User;
import com.redis.test.redistest.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("user")
@Slf4j
public class UserController {

    @Autowired
    UserService userService;

    @PostMapping("register")
    public User saveUser(@RequestBody User user) {
        log.info("Invoking the Controller saveUser for {}", user.getName());
        return userService.saveUser(user);
    }

    @GetMapping("/{name}")
    @Cacheable(value = "users", key = "#name")
    public User findUser(@PathVariable String name) {
        log.info("Invoking the Controller saveUser for {}", name);
        return userService.findUser(name);
    }
}