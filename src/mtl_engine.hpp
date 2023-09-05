#pragma once

// Forward declaration
namespace MTL {
    class RenderCommandEncoder;
}

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

    void createTriangle();
    void createDefaultLibrary();
    void createCommandQueue();
    void createRenderPipeline();



    void encodeRenderCommand(MTL::RenderCommandEncoder *renderEncoder);
    void sendRenderCommand();
    void draw();
    struct Impl;
    Impl *m;


};