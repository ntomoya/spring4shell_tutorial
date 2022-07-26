package com.example.spring4shell;

import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HelloController {

    @RequestMapping("/hello")
    public String hello(HelloModel hello) {
        return hello.hello;
    }

    @RequestMapping("/world")
    public String world(HelloModel hello) {
        return hello.world.message;
    }
}
