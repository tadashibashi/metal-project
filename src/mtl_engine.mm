#include "mtl_engine.hpp"


#define GLFW_INCLUDE_NONE
#import <GLFW/glfw3.h>
#define GLFW_EXPOSE_NATIVE_COCOA
#import <GLFW/glfw3native.h>

#include <Metal/Metal.hpp>
#include <Metal/Metal.h>
#include <QuartzCore/CAMetalLayer.hpp>
#include <QuartzCore/CAMetalLayer.h>
#include <QuartzCore/QuartzCore.hpp>

struct MTLEngine::Impl
{
    MTL::Device *mtlDevice;
    GLFWwindow *window;
    NSWindow *mtlWindow;
    CAMetalLayer *metalLayer;
};

void MTLEngine::init()
{
    initDevice();
    initWindow();
}

void MTLEngine::run()
{
    while (!glfwWindowShouldClose(m->window))
    {
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

    NSWindow *mtlWindow = glfwGetCocoaWindow(window);
    auto metalLayer = [CAMetalLayer layer];
    metalLayer.device = (__bridge id<MTLDevice>)m->mtlDevice;
    metalLayer.pixelFormat = MTLPixelFormatBGRA8Unorm;
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
