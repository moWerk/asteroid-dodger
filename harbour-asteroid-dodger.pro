TARGET = harbour-asteroid-dodger

CONFIG += sailfishapp

SOURCES += src/main.cpp \
    src/DodgerStorage.cpp

HEADERS += src/DodgerStorage.h

DISTFILES += qml/harbour-asteroid-dodger.qml \
    qml/game/*.qml \
    qml/game/qmldir \
    rpm/harbour-asteroid-dodger.spec \
    harbour-asteroid-dodger.desktop

SAILFISHAPP_ICONS = 86x86 108x108 128x128 172x172
