package com.example.spring4shell;

public class HelloModel {
    public String hello;
    public WorldModel world = new WorldModel();

    public String getHello() {
        return hello;
    }

    public void setHello(String hello) {
        this.hello = hello;
    }

    public WorldModel getWorld() {
        return world;
    }
}
