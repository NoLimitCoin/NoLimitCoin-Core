#ifndef OVERVIEWPAGE_H
#define OVERVIEWPAGE_H

#include <QWidget>
#include <stdint.h>

QT_BEGIN_NAMESPACE
class QModelIndex;
QT_END_NAMESPACE

namespace Ui {
    class OverviewPage;
}
class WalletModel;
class TxViewDelegate;
class TransactionFilterProxy;

/** Overview ("home") page widget */
class OverviewPage : public QWidget
{
    Q_OBJECT

public:
    explicit OverviewPage(QWidget *parent = 0);
    ~OverviewPage();

    void setModel(WalletModel *model);
    void showOutOfSyncWarning(bool fShow);

public slots:
    void setBalance(qint64 balance, qint64 stake, qint64 unconfirmedBalance, qint64 immatureBalance);

signals:
    void transactionClicked(const QModelIndex &index);

private:
    Ui::OverviewPage *ui;
    WalletModel *model;
    qint64 currentBalance;
    qint64 currentStake;
    qint64 currentUnconfirmedBalance;
    qint64 currentImmatureBalance;

    TxViewDelegate *txdelegate;
    TransactionFilterProxy *filter;

    uint64_t nWeight;

private slots:
    void updateDisplayUnit();
    void handleTransactionClicked(const QModelIndex &index);

    void updateStakingSwitchToOn();
    void updateStakingSwitchToOff();

    /** Ask for passphrase to unlock wallet temporarily */
    void switchStakingStatus();
    void updateStakingWeights();
    void updateStakingIcon();
    void updateWeight();
};

#endif // OVERVIEWPAGE_H
