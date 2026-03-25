/*
 * Copyright (C) 2025 - Timo Könnecke <github.com/eLtMosen>
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

#include "DodgerStorage.h"
#include <QDir>
#include <QStandardPaths>

static DodgerStorage *s_instance = nullptr;

DodgerStorage::DodgerStorage(QObject *parent)
    : QObject(parent)
    // Explicit path avoids HOME ambiguity in the Lipstick session environment.
    // QSettings creates the file on first sync() if it does not exist.
    , m_settings(
        QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
        + QStringLiteral("/.config/asteroid-dodger/game.ini"),
        QSettings::IniFormat)
{
    // Ensure the config directory exists before any write attempt.
    QDir().mkpath(
        QStandardPaths::writableLocation(QStandardPaths::HomeLocation)
        + QStringLiteral("/.config/asteroid-dodger"));
    s_instance = this;
}

DodgerStorage *DodgerStorage::instance()
{
    if (!s_instance)
        s_instance = new DodgerStorage();
    return s_instance;
}

QObject *DodgerStorage::qmlInstance(QQmlEngine *, QJSEngine *)
{
    return instance();
}

// ── Difficulty ────────────────────────────────────────────────────────────────

QString DodgerStorage::difficulty() const
{
    return m_settings.value(QStringLiteral("difficulty"),
                            QStringLiteral("Cadet Swerver")).toString();
}

void DodgerStorage::setDifficulty(const QString &v)
{
    if (v == difficulty()) return;
    m_settings.setValue(QStringLiteral("difficulty"), v);
    m_settings.sync();
    emit difficultyChanged();
}

// ── Per-difficulty scores ─────────────────────────────────────────────────────

int DodgerStorage::highScore(const QString &diff) const
{
    return m_settings.value(keyFor(diff, QStringLiteral("highScore")), 0).toInt();
}

void DodgerStorage::setHighScore(const QString &diff, int v)
{
    if (v <= highScore(diff)) return;   // never lower the record
    m_settings.setValue(keyFor(diff, QStringLiteral("highScore")), v);
    m_settings.sync();
}

int DodgerStorage::highLevel(const QString &diff) const
{
    return m_settings.value(keyFor(diff, QStringLiteral("highLevel")), 1).toInt();
}

void DodgerStorage::setHighLevel(const QString &diff, int v)
{
    if (v <= highLevel(diff)) return;   // never lower the record
    m_settings.setValue(keyFor(diff, QStringLiteral("highLevel")), v);
    m_settings.sync();
}

// ── Helpers ───────────────────────────────────────────────────────────────────

QString DodgerStorage::fileName() const
{
    return m_settings.fileName();
}

QString DodgerStorage::keyFor(const QString &diff, const QString &field) const
{
    // "Cadet Swerver" + "highScore"  →  "cadet_swerver/highScore"
    // QSettings treats '/' as a group separator, producing clean INI sections.
    return diff.toLower().replace(QLatin1Char(' '), QLatin1Char('_'))
           + QLatin1Char('/') + field;
}
