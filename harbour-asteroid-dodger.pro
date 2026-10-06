# Pure QML, no binary: sailfish-qml (libsailfishapp-launcher) runs
# qml/harbour-asteroid-dodger.qml, so one noarch package serves every architecture.
TEMPLATE = aux
TARGET = harbour-asteroid-dodger

qml.files = qml
qml.path = /usr/share/$${TARGET}
desktop.files = $${TARGET}.desktop
desktop.path = /usr/share/applications
INSTALLS += qml desktop

for(size, $$list(86x86 108x108 128x128 172x172)) {
    icon$${size}.files = icons/$${size}/$${TARGET}.png
    icon$${size}.path = /usr/share/icons/hicolor/$${size}/apps
    INSTALLS += icon$${size}
}

DISTFILES += qml/$${TARGET}.qml \
    $$files(qml/game/*) \
    rpm/$${TARGET}.spec \
    $${TARGET}.desktop
