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
	if (this->model && !loadedBlockchain)
    {	
    	int numBlocks = this->model->getNumBlocks();
    	int totalBlocks = this->model->getNumBlocksOfPeers();
    	QString percentageText = "";

    	if(numBlocks < totalBlocks){
    		float nPercentageDone = numBlocks / (totalBlocks * 0.01f);
    		percentageText = QString::number(nPercentageDone) + "%";
    	} else if( (numBlocks == totalBlocks) || (numBlocks - totalBlocks < 10)) {
    		percentageText = "100%";
    		loadedBlockchain = true;
    	}

        ui->loadingText->setText("Syncing the blockchain... " + percentageText);

        //loadedBlockchain = true;
        if(loadedBlockchain){
		    emit blockchainLoaded();
        }
    }
}
