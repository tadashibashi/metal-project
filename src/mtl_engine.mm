#include "mtl_engine.hpp"
#include <iostream>


#define GLFW_INCLUDE_NONE
#import <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_COCOA
#import <GLFW/glfw3native.h>

#include <Metal/Metal.hpp>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.hpp>
#include <QuartzCore/CAMetalLayer.h>
#include <QuartzCore/QuartzCore.hpp>
#include <Metal/MTLRenderCommandEncoder.hpp>

#include <simd/simd.h>

struct MTLEngine::Impl
{
    MTL::Device *mtlDevice;
    GLFWwindow *window;
    NSWindow *mtlWindow;
    CAMetalLayer *metalLayer;

    CA::MetalDrawable *metalDrawable;

    MTL::Library *metalDefaultLibrary;
    MTL::CommandQueue *metalCommandQueue;
    MTL::CommandBuffer *metalCommandBuffer;
    MTL::RenderPipelineState *metalRenderPSO;
    MTL::Buffer *triangleVertexBuffer;
};

void MTLEngine::init()
{
    initDevice();
    initWindow();
    createTriangle();
    createDefaultLibrary();
    createCommandQueue();
    createRenderPipeline();
}

void MTLEngine::run()
{
    while (!glfwWindowShouldClose(m->window))
    {
        @autoreleasepool {
            m->metalDrawable = (__bridge CA::MetalDrawable *)[m->metalLayer nextDrawable];
            draw();
        }
        glfwPollEvents();
    }
}

void MTLEngine::cleanup()
{
    glfwTerminate();
    m->mtlDevice->release();
}

void MTLEngine::initDevice()
{
    m->mtlDevice = MTL::CreateSystemDefaultDevice();
}

void MTLEngine::initWindow()
{
    glfwInit();
    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);
    auto window = glfwCreateWindow(800, 600, "Metal Engine", nullptr, nullptr);
    if (!window)
    {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    // Get the framebuffer size to set metalLayer drawable size
    // Workaround for bug in glfw / MacOS where Mac's window size
    // isn't always the draw size. It scales based on DPI scaling.
    // Screen drawing may look fuzzy if not set.
    int width, height;
    glfwGetFramebufferSize(window, &width, &height);

    NSWindow *mtlWindow = glfwGetCocoaWindow(window);
    auto metalLayer = [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)m->mtlDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
    metalLayer.drawableSize = CGSizeMake(width, height);
    mtlWindow.contentView.layer = metalLayer;
    mtlWindow.contentView.wantsLayer = YES;

    m->window = window;
    m->mtlWindow = mtlWindow;
    m->metalLayer = metalLayer;
}

MTLEngine::MTLEngine() : m(new Impl)
{

}

MTLEngine::~MTLEngine()
{
    delete m;
}

void MTLEngine::createTriangle()
{
    simd::float3 triangleVertices[] = {
            {-0.5f, -0.5f, 0.0f},
            {0.5f, -0.5f, 0.0f},
            {0.0f, 0.5f, 0.0f},
    };

    m->triangleVertexBuffer = m->mtlDevice->newBuffer(&triangleVertices,
                                                      sizeof(triangleVertices),
                                                      MTL::ResourceStorageModeShared);
}

void MTLEngine::createDefaultLibrary()
{
    m->metalDefaultLibrary = m->mtlDevice->newDefaultLibrary();
    if (!m->metalDefaultLibrary)
    {
        std::cerr << "Failed to load default library.\n";
        exit(-1);
    }
}

void MTLEngine::createCommandQueue()
{
    m->metalCommandQueue = m->mtlDevice->newCommandQueue();
}

void MTLEngine::createRenderPipeline()
{
    MTL::Function *vertexShader = m->metalDefaultLibrary->newFunction(NS::String::string("vertexShader", NS::ASCIIStringEncoding));
    assert(vertexShader);
    MTL::Function *fragmentShader = m->metalDefaultLibrary->newFunction(NS::String::string("fragmentShader", NS::ASCIIStringEncoding));
    assert(fragmentShader);

    auto renderPipeLineDescriptor = MTL::RenderPipelineDescriptor::alloc()->init();
    renderPipeLineDescriptor->setLabel(NS::String::string("Triangle Rendering Pipeline", NS::ASCIIStringEncoding));
    renderPipeLineDescriptor->setVertexFunction(vertexShader);
    renderPipeLineDescriptor->setFragmentFunction(fragmentShader);
    assert(renderPipeLineDescriptor);
    auto pixelFormat = (MTL::PixelFormat)m->metalLayer.pixelFormat;
    renderPipeLineDescriptor->colorAttachments()->object(0)->setPixelFormat(pixelFormat);

    NS::Error *error;
    m->metalRenderPSO = m->mtlDevice->newRenderPipelineState(renderPipeLineDescriptor, &error);

    renderPipeLineDescriptor->release();
}

void MTLEngine::encodeRenderCommand(MTL::RenderCommandEncoder *renderCommandEncoder)
{
    renderCommandEncoder->setRenderPipelineState(m->metalRenderPSO);
    renderCommandEncoder->setVertexBuffer(m->triangleVertexBuffer, 0, 0);
    MTL::PrimitiveType typeTriangle = MTL::PrimitiveTypeTriangle;
    NS::UInteger vertexStart = 0;
    NS::UInteger vertexCount = 3;
    renderCommandEncoder->drawPrimitives(typeTriangle, vertexStart, vertexCount);
}

void MTLEngine::sendRenderCommand()
{
    m->metalCommandBuffer = m->metalCommandQueue->commandBuffer();

    MTL::RenderPassDescriptor *renderPassDescriptor = MTL::RenderPassDescriptor::alloc()->init();
    MTL::RenderPassColorAttachmentDescriptor *cd = renderPassDescriptor->colorAttachments()->object(0);
    cd->setTexture(m->metalDrawable->texture());
    cd->setLoadAction(MTL::LoadActionClear);
    cd->setClearColor(MTL::ClearColor(41.0f/255.0f, 42.0f/255.0f, 48.0f/255.0f, 1.0));
    cd->setStoreAction(MTL::StoreActionStore);

    MTL::RenderCommandEncoder *renderCommandEncoder = m->metalCommandBuffer->renderCommandEncoder(renderPassDescriptor);
    encodeRenderCommand(renderCommandEncoder);
    renderCommandEncoder->endEncoding();

    m->metalCommandBuffer->presentDrawable(m->metalDrawable);
    m->metalCommandBuffer->commit();
    m->metalCommandBuffer->waitUntilCompleted();

    renderPassDescriptor->release();
}

void MTLEngine::draw()
{
    sendRenderCommand();
}
