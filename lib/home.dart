import 'package:flutter/material.dart';
import 'package:shrine/models.dart';
import 'package:shrine/repository.dart';
import 'package:shrine/widgets.dart';

class HomePage extends StatelessWidget {
  final Category category;

  const HomePage({this.category = Category.all, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AsymmetricView(products: ProductsRepository.loadProducts(category));
  }
}
