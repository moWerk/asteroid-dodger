cmake_minimum_required(VERSION 3.6.0)

project(asteroid-dodger
    VERSION 2.0
    DESCRIPTION "A thrilling survival game for AsteroidOS where you tilt your watch to surf through an ever-denser asteroid field")

find_package(ECM REQUIRED NO_MODULE)
find_package(AsteroidApp6 REQUIRED)

set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH} ${ASTEROID_MODULE_PATH})

include(FeatureSummary)
include(GNUInstallDirs)
include(ECMFindQmlModule)
include(Asteroid6CMakeSettings)
include(Asteroid6Translations)

add_executable(asteroid-dodger
    main.cpp
    DodgerStorage.cpp
    resources.qrc)

target_link_libraries(asteroid-dodger PRIVATE
    Asteroid::AsteroidApp6)

install(TARGETS asteroid-dodger DESTINATION ${CMAKE_INSTALL_BINDIR})
install(FILES asteroid-dodger.desktop
        DESTINATION /usr/share/applications/)
install(FILES asteroid-dodger.svg
        DESTINATION /usr/share/icons/asteroid/)
