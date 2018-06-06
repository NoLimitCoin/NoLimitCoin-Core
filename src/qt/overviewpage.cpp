#include "overviewpage.h"
#include "ui_overviewpage.h"

#include "clientmodel.h"
#include "walletmodel.h"
#include "bitcoinunits.h"
#include "optionsmodel.h"
#include "transactiontablemodel.h"
#include "transactionfilterproxy.h"
#include "guiutil.h"
#include "guiconstants.h"
#include "askpassphrasedialog.h"
#include "wallet.h"

#include <QAbstractItemDelegate>
#include <QPainter>
#include <QTableView>
#include <QTimer>

#define DECORATION_SIZE 64
#define NUM_ITEMS 6

extern CWallet* pwalletMain;
extern int64_t nLastCoinStakeSearchInterval;
double GetPoSKernelPS();

class TxViewDelegate : public QAbstractItemDelegate
{
    Q_OBJECT
public:
    TxViewDelegate(): QAbstractItemDelegate(), unit(BitcoinUnits::BTC)
    {

    }

    inline void paint(QPainter *painter, const QStyleOptionViewItem &option,
                      const QModelIndex &index ) const {
    }

    inline QSize sizeHint(const QStyleOptionViewItem &option, const QModelIndex &index) const
    {
        return QSize(DECORATION_SIZE, DECORATION_SIZE);
    }

    int unit;

};
#include "overviewpage.moc"

OverviewPage::OverviewPage(QWidget *parent) :
    QWidget(parent),
    ui(new Ui::OverviewPage),
    currentBalance(-1),
    currentStake(0),
    currentUnconfirmedBalance(-1),
    currentImmatureBalance(-1),
    txdelegate(new TxViewDelegate()),
    filter(0),
    nWeight(0)
{
    ui->setupUi(this);

    // Recent transactions
    ui->listTransactions->setMinimumHeight(NUM_ITEMS * (DECORATION_SIZE + 2));

    // Transactions table styling
    this->setStyleSheet("QTableView {background-color: transparent;}"
              "QHeaderView::section {background-color: transparent;}"
              "QHeaderView {background-color: transparent;}"
              "QTableCornerButton::section {background-color: transparent;}");    

    connect(ui->listTransactions, SIGNAL(clicked(QModelIndex)), this, SLOT(handleTransactionClicked(QModelIndex)));
    connect(ui->stakingSwitch, SIGNAL(clicked()), this, SLOT(switchStakingStatus()));

    QTimer *timerStakingIcon = new QTimer(ui->stakingStatusLabel);
    connect(timerStakingIcon, SIGNAL(timeout()), this, SLOT(updateStakingWeights()));
    timerStakingIcon->start(30 * 1000);

    updateStakingWeights();
}

void OverviewPage::handleTransactionClicked(const QModelIndex &index)
{
    if(filter)
        emit transactionClicked(filter->mapToSource(index));
}

OverviewPage::~OverviewPage()
{
    delete ui;
}

void OverviewPage::setBalance(qint64 balance, qint64 stake, qint64 unconfirmedBalance, qint64 immatureBalance)
{
    int unit = model->getOptionsModel()->getDisplayUnit();
    currentBalance = balance;
    currentStake = stake;
    currentUnconfirmedBalance = unconfirmedBalance;
    currentImmatureBalance = immatureBalance;
    ui->labelBalance->setText(BitcoinUnits::formatWithUnit(unit, balance));
    ui->labelStake->setText(BitcoinUnits::formatWithUnit(unit, stake));
    ui->labelUnconfirmed->setText(BitcoinUnits::formatWithUnit(unit, unconfirmedBalance));
    ui->labelImmature->setText(BitcoinUnits::formatWithUnit(unit, immatureBalance));
    ui->labelTotal->setText(BitcoinUnits::formatWithUnit(unit, balance + stake + unconfirmedBalance + immatureBalance));

    // only show immature (newly mined) balance if it's non-zero, so as not to complicate things
    // for the non-mining users
    bool showImmature = immatureBalance != 0;
    ui->labelImmature->setVisible(showImmature);
    ui->labelImmatureText->setVisible(showImmature);
}

void OverviewPage::setClientModel(ClientModel *model) {
    this->clientModel = model;

    setNumBlocks(clientModel->getNumBlocks(), clientModel->getNumBlocksOfPeers());
    connect(clientModel, SIGNAL(numBlocksChanged(int,int)), this, SLOT(setNumBlocks(int,int)));
}

void OverviewPage::setModel(WalletModel *model)
{
    this->model = model;
    if(model && model->getOptionsModel())
    {
        // Set up transaction list
        filter = new TransactionFilterProxy();
        filter->setSourceModel(model->getTransactionTableModel());
        filter->setLimit(NUM_ITEMS);
        filter->setDynamicSortFilter(true);
        filter->setSortRole(Qt::EditRole);
        filter->setShowInactive(false);
        filter->sort(TransactionTableModel::Status, Qt::DescendingOrder);

        // QStringList labelList;
        filter->setHeaderData(0, Qt::Horizontal, tr("Name"));
        filter->setHeaderData(1, Qt::Horizontal, tr("Salary"));

        ui->listTransactions->setModel(filter);

        // Column resizing
        ui->listTransactions->horizontalHeader()->resizeSection(
                TransactionTableModel::Confirmations, 28);
        ui->listTransactions->horizontalHeader()->resizeSection(
                TransactionTableModel::Status, 28);
        ui->listTransactions->horizontalHeader()->resizeSection(
                TransactionTableModel::Date, 180);
        ui->listTransactions->horizontalHeader()->resizeSection(
                TransactionTableModel::Type, 80);
        ui->listTransactions->horizontalHeader()->resizeSection(
                TransactionTableModel::ToAddress, 280 );
        ui->listTransactions->horizontalHeader()->setResizeMode(
                TransactionTableModel::Amount, QHeaderView::Stretch);
        

        // Keep up to date with wallet
        setBalance(model->getBalance(), model->getStake(), model->getUnconfirmedBalance(), model->getImmatureBalance());
        connect(model, SIGNAL(balanceChanged(qint64, qint64, qint64, qint64)), this, SLOT(setBalance(qint64, qint64, qint64, qint64)));

        connect(model->getOptionsModel(), SIGNAL(displayUnitChanged(int)), this, SLOT(updateDisplayUnit()));
        connect(model, SIGNAL(encryptionStatusChanged(int)), this, SLOT(updateStakingIcon()));

        updateStakingIcon();
    }

    // update the display unit, to not use the default ("BTC")
    updateDisplayUnit();
}

void OverviewPage::updateDisplayUnit()
{
    if(model && model->getOptionsModel())
    {
        if(currentBalance != -1)
            setBalance(currentBalance, model->getStake(), currentUnconfirmedBalance, currentImmatureBalance);

        // Update txdelegate->unit with the current unit
        txdelegate->unit = model->getOptionsModel()->getDisplayUnit();

        ui->listTransactions->update();
    }
}

void OverviewPage::showOutOfSyncWarning(bool fShow)
{
    // ui->labelWalletStatus->setVisible(fShow);
    // ui->labelTransactionsStatus->setVisible(fShow);
}

void OverviewPage::updateStakingSwitchToOn(){
     ui->stakingSwitch->setIcon(QIcon(":/icons/staking_switch_on"));
     ui->stakingStatusLabel->setText("On");
}

void OverviewPage::updateStakingSwitchToOff(){
     ui->stakingSwitch->setIcon(QIcon(":/icons/staking_switch_off"));
     ui->stakingStatusLabel->setText("Off");
}

void OverviewPage::updateStakingIcon()
{
    if(!model)
        return;

    if(model->getEncryptionStatus() == WalletModel::Locked)
        updateStakingSwitchToOff();
    else
        updateStakingSwitchToOn();
}


void OverviewPage::switchStakingStatus() {
    if(!model || model->getEncryptionStatus() == WalletModel::Unencrypted)
        return;
    // Unlock wallet when requested by wallet model
    if(model->getEncryptionStatus() == WalletModel::Locked)
    {
        AskPassphraseDialog::Mode mode = AskPassphraseDialog::UnlockStaking ;
        AskPassphraseDialog dlg(mode, this);
        dlg.setModel(model);
        connect(&dlg, SIGNAL(accepted()), this, SLOT(updateStakingSwitchToOn()));

        dlg.exec();
    } else {
        model->setWalletLocked(true);
        updateStakingSwitchToOff();
    }
}

void OverviewPage::updateWeight()
{
    if (!pwalletMain)
        return;

    TRY_LOCK(cs_main, lockMain);
    if (!lockMain)
        return;

    TRY_LOCK(pwalletMain->cs_wallet, lockWallet);
    if (!lockWallet)
        return;

    uint64_t nMinWeight = 0, nMaxWeight = 0;
    pwalletMain->GetStakeWeight(*pwalletMain, nMinWeight, nMaxWeight, nWeight);
}

void OverviewPage::updateStakingWeights() {
    updateWeight();
    uint64_t nNetworkWeight = GetPoSKernelPS();

    ui->stakingWeightText->setText(QString::number(nWeight));
    ui->networkWeightText->setText(QString::number(nNetworkWeight));
}

void OverviewPage::setNumBlocks(int count, int nTotalBlocks)
{
    // don't show label if we have no connection to the network
    if (!clientModel || clientModel->getNumConnections() == 0)
        return;

    QString strStatusBarWarnings = clientModel->getStatusBarWarnings();
    QString percentageDone;

    if(count < nTotalBlocks)
    {
        int nRemainingBlocks = nTotalBlocks - count;
        float nPercentageDone = count / (nTotalBlocks * 0.01f);

        percentageDone = tr("%1").arg(nPercentageDone, 0, 'f', 2);
        ui->syncText->setText("Syncing the Blockchain ... " + percentageDone);
    }
   
    QDateTime lastBlockDate = clientModel->getLastBlockDate();
    int secs = lastBlockDate.secsTo(QDateTime::currentDateTime());

    // Set icon state: spinning if catching up, tick otherwise
    if(secs < 90*60 && count >= nTotalBlocks)
      ;
    else
        ui->syncText->setText("Syncing the Blockchain ...");
}
