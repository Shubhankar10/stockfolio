import 'package:flutter/material.dart';
import 'package:stockfolio/features/stocks/screens/sell2.dart';
import 'package:stockfolio/models/stock_transaction_model.dart';
import 'package:stockfolio/utils/Colors.dart';
import 'package:stockfolio/utils/utils.dart';
import 'package:stockfolio/widgets/custom_button.dart';

class Sell extends StatefulWidget {
  const Sell({super.key, required this.userStocksList});

  final List<StockTransactionModel> userStocksList;

  @override
  State<Sell> createState() => _SellState();
}

class _SellState extends State<Sell> {
  final TextEditingController searchController = TextEditingController();
  String searchText = '';
  String selectedStockExc = '';
  StockTransactionModel? selectedStock;
  List<StockTransactionModel> groupedUserHoldings = [];
  List<StockTransactionModel> filteredStocksList = [];

  void initSellStocksList() {
    final Map<String, StockTransactionModel> userHoldingsMap = {};
    widget.userStocksList.sort(
      (a, b) => a.transactionDate!.compareTo(b.transactionDate!),
    );

    for (final StockTransactionModel transaction in widget.userStocksList) {
      final stockSymbol = transaction.stockSymbol;
      final isBuy = transaction.isBought ?? false;
      final transactionQuantity = transaction.quantity ?? 0;

      if (userHoldingsMap.containsKey(stockSymbol)) {
        var currentHolding = userHoldingsMap[stockSymbol];
        if (currentHolding != null) {
          // Pehale k sab transaction ka price calc hua
          final totalPrice =
              (currentHolding.price ?? 0) * (currentHolding.quantity ?? 0);
          // Abhi vale ka price calc hua
          final transactionAmount = transaction.price! * transactionQuantity;

          //Dono ko add kar do agar buy hai nai toh minus
          final double newTotalPrice;

          if (isBuy) {
            newTotalPrice = totalPrice + transactionAmount;
            currentHolding.quantity =
                (currentHolding.quantity ?? 0) + transactionQuantity;
          } else {
            newTotalPrice = totalPrice - transactionAmount;
            final currentQuantity = currentHolding.quantity ?? 0;
            if (currentQuantity >= transactionQuantity) {
              currentHolding.quantity = currentQuantity - transactionQuantity;
            } else {
              print("Sold More than Owned");
            }
          }

          // Update the price as the average price
          if (currentHolding.quantity != 0) {
            currentHolding.price = newTotalPrice /
                (currentHolding.quantity ?? 1); // Prevent division by zero
          } else {
            // Set price to 0 if quantity is 0
            currentHolding.price = 0;
          }
          if (currentHolding.quantity == 0) {
            userHoldingsMap.remove(stockSymbol);
          }
        }
      } else {
        userHoldingsMap.putIfAbsent(
          stockSymbol!,
          () => transaction,
        );
      }
    }

    groupedUserHoldings = userHoldingsMap.values.toList();
  }

  @override
  void initState() {
    super.initState();
    initSellStocksList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(15),
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  onTapOutside: (PointerDownEvent event) =>
                      FocusManager.instance.primaryFocus?.unfocus(),
                  showCursor: true,
                  onChanged: (value) {
                    searchText = value;
                    if (searchText.isEmpty) {
                      filteredStocksList.clear();
                    }
                    setState(() {
                      filteredStocksList = groupedUserHoldings
                          .where(
                            (stock) => stock.stockSymbol!
                                .toLowerCase()
                                .contains(searchText.toLowerCase()),
                          )
                          .toList();
                    });
                  },
                  cursorColor: AppColors.black,
                  controller: searchController,
                  keyboardType: TextInputType.name,
                  decoration: InputDecoration(
                    prefixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: AppColors.blue,
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    suffixIcon: const Icon(
                      Icons.expand_circle_down_rounded,
                      size: 20,
                      color: AppColors.blue,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    hintText: 'Enter Stock Symbol',
                    labelText: 'Stock Symbol',
                    hintStyle: const TextStyle(
                      fontWeight: FontWeight.w300,
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w300,
                      color: AppColors.blue,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    fillColor: Colors.transparent,
                    filled: true,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredStocksList.length > 5
                    ? 5
                    : filteredStocksList.length,
                itemBuilder: (BuildContext context, int index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 5,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        title: Text(
                          filteredStocksList[index].stockSymbol!,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          filteredStocksList[index].exchangeName!,
                          style: const TextStyle(
                            fontSize: 12,
                          ),
                        ),
                        trailing: Text(
                          filteredStocksList[index].price!.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onTap: () {
                          if (!context.mounted) {
                            return;
                          }
                          setState(() {
                            searchController.text =
                                filteredStocksList[index].stockSymbol!;
                            selectedStock = filteredStocksList[index];
                            filteredStocksList.clear();
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
              // const Text('Current Holding'),
              const SizedBox(
                height: 20,
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: CustomButton(
                  text: 'Next',
                  onPressed: () {
                    if (searchController.text.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SellNext(
                            selectedStockModel: selectedStock!,
                          ),
                        ),
                      );
                    } else {
                      showSnackBar(
                        context,
                        'Please enter the stock symbol to sell',
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
