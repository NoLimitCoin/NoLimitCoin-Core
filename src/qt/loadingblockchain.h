#ifndef LOADINGBLOCKCHAIN_H
#define LOADINGBLOCKCHAIN_H

#include <QWidget>

namespace Ui {
class LoadingBlockchain;
}

class LoadingBlockchain : public QWidget
{
    Q_OBJECT

public:
    explicit LoadingBlockchain(QWidget *parent = 0);
    ~LoadingBlockchain();

private:
    Ui::LoadingBlockchain *ui;
};

#endif // LOADINGBLOCKCHAIN_H
