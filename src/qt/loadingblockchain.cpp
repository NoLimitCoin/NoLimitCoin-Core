#include "loadingblockchain.h"
#include "ui_loadingblockchain.h"

LoadingBlockchain::LoadingBlockchain(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::LoadingBlockchain)
{
    ui->setupUi(this);
}

LoadingBlockchain::~LoadingBlockchain()
{
    delete ui;
}
