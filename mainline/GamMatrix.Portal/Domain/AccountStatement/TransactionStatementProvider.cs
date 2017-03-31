using System;
using GamMatrix.CMS.Domain.AccountStatement.Statements;
using GamMatrixAPI;

namespace GamMatrix.CMS.Domain.AccountStatement
{
	public class TransactionStatementProvider
	{
		public ITransactionStatement CreateStatement(TransactionStatementType transactionType)
		{
			ITransactionStatement transactionStatement;

			switch (transactionType)
			{
				case TransactionStatementType.Deposit:
					transactionStatement = new DepositStatement();
					break;
				case TransactionStatementType.Withdraw:
					transactionStatement = new WithdrawalStatement();
					break;
				case TransactionStatementType.Transfer:
					transactionStatement = new TransferStatement();
					break;
				case TransactionStatementType.BuddyTransfer:
					transactionStatement = new BuddyTransferStatement();
					break;
				case TransactionStatementType.CasinoFPP:
					transactionStatement = new CasinoFPPStatement();
					break;
				case TransactionStatementType.AffiliateFee:
					transactionStatement = new AffiliateFeeStatement();
					break;
				case TransactionStatementType.CasinoWalletCreditDebit:
					transactionStatement = new WalletStatement(VendorID.CasinoWallet);
					break;
				case TransactionStatementType.MicrogamingWalletCreditDebit:
					transactionStatement = new WalletStatement(VendorID.Microgaming);
					break;
				case TransactionStatementType.ViGWalletCreditDebit:
					transactionStatement = new WalletStatement(VendorID.ViG);
					break;
				case TransactionStatementType.IGTWalletCreditDebit:
					transactionStatement = new WalletStatement(VendorID.IGT);
					break;
				default:
					throw new NotSupportedException("Transaction type not supported");
			}

			return transactionStatement;
		}
	}
}
