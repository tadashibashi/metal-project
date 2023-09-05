#include "mtl_engine.hpp"

int main(int argc, char *argv[])
{
    MTLEngine engine;

    engine.init();
    engine.run();
    engine.cleanup();

    return 0;
}
