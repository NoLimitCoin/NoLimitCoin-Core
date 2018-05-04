#ifndef NOCONNECTION_H
#define NOCONNECTION_H

#include <QWidget>

namespace Ui {
class NoConnection;
}

class NoConnection : public QWidget
{
    Q_OBJECT

public:
    explicit NoConnection(QWidget *parent = 0);
    ~NoConnection();

private:
    Ui::NoConnection *ui;
};

#endif // NOCONNECTION_H
