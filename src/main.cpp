/*
 * Copyright (C) 2026 - Timo Könnecke <github.com/moWerk>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */


#include <sailfishapp.h>
#include <QFontDatabase>
#include <QGuiApplication>
#include <QQuickView>
#include <QScopedPointer>
#include <QtQml>
#include "DodgerStorage.h"

int main(int argc, char *argv[])
{
    QScopedPointer<QGuiApplication> app(SailfishApp::application(argc, argv));
    app->setOrganizationName(QStringLiteral("net.mowerk"));
    app->setApplicationName(QStringLiteral("harbour-asteroid-dodger"));

    qmlRegisterSingletonType<DodgerStorage>(
        "org.asteroid.dodger", 1, 0,
        "DodgerStorage",
        DodgerStorage::qmlInstance);

    // The game asks for the font "Fyodor" by name. AsteroidOS has it
    // system wide, here it comes with the app. It has to be known before
    // the first Text is created.
    QFontDatabase::addApplicationFont(
        SailfishApp::pathTo(QStringLiteral("qml/game/fonts/Fyodor-BoldCondensed.ttf")).toLocalFile());

    QScopedPointer<QQuickView> view(SailfishApp::createView());
    view->setSource(SailfishApp::pathToMainQml());
    view->show();
    return app->exec();
}
