#include "loadingblockchain.h"
#include "ui_loadingblockchain.h"
#include "clientmodel.h"

LoadingBlockchain::LoadingBlockchain(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::LoadingBlockchain)
{
    ui->setupUi(this);
}

LoadingBlockchain::~LoadingBlockchain() {
    delete ui;
}

void LoadingBlockchain::setModel(ClientModel *model) {
    this->model = model;
    updateProgress();
    connect(this->model, SIGNAL(numBlocksChanged(int,int)), this, SLOT(updateProgress()));
    
}

void LoadingBlockchain::updateProgress() {
	if (this->model)
    {
    	float nPercentageDone = this->model->getNumBlocks() / (this->model->getNumBlocksOfPeers() * 0.01f);	
        ui->loadingText->setText("Syncing the blockchain... " + QString::number(nPercentageDone) + "%");
    }
}
