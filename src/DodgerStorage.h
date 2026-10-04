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

#ifndef DODGERSTORAGE_H
#define DODGERSTORAGE_H

#include <QObject>
#include <QSettings>
#include <QString>
#include <QQmlEngine>

class DodgerStorage : public QObject
{
    Q_OBJECT

    // Last-used difficulty persisted across sessions.
    // Value is the full display name, e.g. "Cadet Swerver".
    Q_PROPERTY(QString difficulty READ difficulty WRITE setDifficulty NOTIFY difficultyChanged)

public:
    explicit DodgerStorage(QObject *parent = nullptr);
    static DodgerStorage *instance();
    static QObject *qmlInstance(QQmlEngine *engine, QJSEngine *scriptEngine);

    QString difficulty() const;
    void    setDifficulty(const QString &v);

    // Per-difficulty high score and max level.
    // Write-guards in setters: value is only stored if it exceeds the
    // current record, so callers can pass current values unconditionally.
    Q_INVOKABLE int  highScore(const QString &difficulty) const;
    Q_INVOKABLE void setHighScore(const QString &difficulty, int v);
    Q_INVOKABLE int  highLevel(const QString &difficulty) const;
    Q_INVOKABLE void setHighLevel(const QString &difficulty, int v);

    Q_INVOKABLE QString fileName() const;

signals:
    void difficultyChanged();

private:
    // Maps display name + field to an INI group/key, e.g.
    // ("Cadet Swerver", "highScore") → "cadet_swerver/highScore"
    QString keyFor(const QString &difficulty, const QString &field) const;

    QSettings m_settings;
};

#endif // DODGERSTORAGE_H
