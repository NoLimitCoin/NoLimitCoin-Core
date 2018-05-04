#include "noconnection.h"
#include "ui_noconnection.h"

NoConnection::NoConnection(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::NoConnection)
{
    ui->setupUi(this);
}

NoConnection::~NoConnection()
{
    delete ui;
}
