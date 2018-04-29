#include "overviewpage.h"
#include "ui_overviewpage.h"

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

#define DECORATION_SIZE 64
#define NUM_ITEMS 6

extern CWallet* pwalletMain;
extern int64_t nLastCoinStakeSearchInterval;

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
    //ui->listTransactions->setItemDelegate(txdelegate);
    //ui->listTransactions->setIconSize(QSize(DECORATION_SIZE, DECORATION_SIZE));
    ui->listTransactions->setMinimumHeight(NUM_ITEMS * (DECORATION_SIZE + 2));
    //ui->listTransactions->setAttribute(Qt::WA_MacShowFocusRect, false);

    // Transactions table styling
    this->setStyleSheet("QTableView {background-color: transparent;}"
              "QHeaderView::section {background-color: transparent;}"
              "QHeaderView {background-color: transparent;}"
              "QTableCornerButton::section {background-color: transparent;}");    

    ui->listTransactions->setGridStyle(Qt::NoPen);
    ui->listTransactions->setStyleSheet("alternate-background-color: #393939; background-color: #252525;");
    ui->listTransactions->horizontalHeader()->setDefaultAlignment(Qt::AlignLeft);

    connect(ui->listTransactions, SIGNAL(clicked(QModelIndex)), this, SLOT(handleTransactionClicked(QModelIndex)));

    updateStakingIcon();
    connect(ui->stakingSwitch, SIGNAL(clicked()), this, SLOT(switchStakingStatus()));
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
        // labelList << "Alarm Name" << "Time" << "Enabled";
        filter->setHeaderData(0, Qt::Horizontal, tr("Name"));
        filter->setHeaderData(1, Qt::Horizontal, tr("Salary"));

        ui->listTransactions->setModel(filter);

        #ifdef _WIN32
            ui->listTransactions->horizontalHeader()->setResizeMode(QHeaderView::Stretch); 
        #else
            ui->listTransactions->horizontalHeader()->setSectionResizeMode(QHeaderView::Stretch);
        #endif
        

        //ui->listTransactions->setModelColumn(TransactionTableModel::ToAddress);

        // Keep up to date with wallet
        setBalance(model->getBalance(), model->getStake(), model->getUnconfirmedBalance(), model->getImmatureBalance());
        connect(model, SIGNAL(balanceChanged(qint64, qint64, qint64, qint64)), this, SLOT(setBalance(qint64, qint64, qint64, qint64)));

        connect(model->getOptionsModel(), SIGNAL(displayUnitChanged(int)), this, SLOT(updateDisplayUnit()));
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
     ui->stakingSwitch->setIcon(QIcon(":/icons/staking_on").pixmap(21,40));
}

void OverviewPage::updateStakingSwitchToOff(){
     ui->stakingSwitch->setIcon(QIcon(":/icons/staking_off").pixmap(21,40));
}

void OverviewPage::updateStakingIcon()
{
    if (nLastCoinStakeSearchInterval && nWeight)
        updateStakingSwitchToOn();
    else 
       updateStakingSwitchToOff();
}


void OverviewPage::switchStakingStatus() {
    if(!model)
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
