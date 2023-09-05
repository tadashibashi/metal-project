#pragma once

class MTLEngine {
public:
    MTLEngine();
    ~MTLEngine();
    void init();
    void run();
    void cleanup();

private:
    void initDevice();
    void initWindow();

    struct Impl;
    Impl *m;


};