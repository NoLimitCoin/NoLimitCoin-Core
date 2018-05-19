#include "loadingblockchain.h"
#include "ui_loadingblockchain.h"
#include "clientmodel.h"

#include <QMovie>
#include <QTimer>

LoadingBlockchain::LoadingBlockchain(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::LoadingBlockchain)
{
    ui->setupUi(this);

    QMovie *movie = new QMovie(":/movies/loading");
    movie->setScaledSize(QSize(75,75));
    ui->loaderLabel->setMovie(movie);
    movie->start();

    noConnectionTimer = new QTimer(this);
    connect(noConnectionTimer, SIGNAL(timeout()), this, SLOT(emitNoConnectionWarning()));
    noConnectionTimer-> setSingleShot(true);
    noConnectionTimer->start(900000);
}

LoadingBlockchain::~LoadingBlockchain() {
    delete ui;
}

void LoadingBlockchain::setModel(ClientModel *model) {
    this->model = model;
    updateProgress();
    connect(this->model, SIGNAL(numBlocksChanged(int,int)), this, SLOT(updateProgress()));
    connect(this->model, SIGNAL(numConnectionsChanged(int)), this, SLOT(stopNoConnectionTimer()));
    
}

void LoadingBlockchain::updateProgress() {
	if (this->model && !loadedBlockchain)
    {	
    	int numBlocks = this->model->getNumBlocks();
    	int totalBlocks = this->model->getNumBlocksOfPeers();
    	QString percentageText = "";

    	if(numBlocks < totalBlocks){
    		float nPercentageDone = numBlocks / (totalBlocks * 0.01f);
    		percentageText = QString::number(nPercentageDone, 'f', 2) + "%";
    	} else if( ((numBlocks > 0) && (numBlocks == totalBlocks)) || (numBlocks - totalBlocks < 10)) {
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

void LoadingBlockchain::stopNoConnectionTimer() {
    noConnectionTimer->blockSignals(true);
    noConnectionTimer->stop();
}

void LoadingBlockchain::emitNoConnectionWarning() {
    emit showNoConnectionWarning();
}