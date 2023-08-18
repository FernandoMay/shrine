import 'package:flutter/material.dart';
import 'package:shrine/login.dart';
import 'package:shrine/models.dart';

import 'package:intl/intl.dart';

import 'dart:ui' show lerpDouble;

const double _kFlingVelocity = 2.0;

class _FrontLayer extends StatelessWidget {
  const _FrontLayer({
    Key? key,
    this.onTap,
    required this.child,
  }) : super(key: key);

  final VoidCallback? onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 16.0,
      shape: const BeveledRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(46.0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: Container(
              height: 40.0,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }
}

class _BackdropTitle extends AnimatedWidget {
  final void Function() onPress;
  final Widget frontTitle;
  final Widget backTitle;

  const _BackdropTitle({
    Key? key,
    required Animation<double> listenable,
    required this.onPress,
    required this.frontTitle,
    required this.backTitle,
  })  : _listenable = listenable,
        super(key: key, listenable: listenable);

  final Animation<double> _listenable;

  @override
  Widget build(BuildContext context) {
    final Animation<double> animation = _listenable;

    return DefaultTextStyle(
      style: Theme.of(context).textTheme.titleLarge!,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      child: Row(children: <Widget>[
        // branded icon
        SizedBox(
          width: 72.0,
          child: IconButton(
            padding: const EdgeInsets.only(right: 8.0),
            onPressed: onPress,
            icon: Stack(children: <Widget>[
              Opacity(
                opacity: animation.value,
                child: const ImageIcon(AssetImage('assets/slanted_menu.png')),
              ),
              FractionalTranslation(
                translation: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(1.0, 0.0),
                ).evaluate(animation),
                child: const ImageIcon(AssetImage('assets/diamond.png')),
              )
            ]),
          ),
        ),
        // Here, we do a custom cross fade between backTitle and frontTitle.
        // This makes a smooth animation between the two texts.
        Stack(
          children: <Widget>[
            Opacity(
              opacity: CurvedAnimation(
                parent: ReverseAnimation(animation),
                curve: const Interval(0.5, 1.0),
              ).value,
              child: FractionalTranslation(
                translation: Tween<Offset>(
                  begin: Offset.zero,
                  end: const Offset(0.5, 0.0),
                ).evaluate(animation),
                child: Semantics(
                    label: 'hide categories menu',
                    child: ExcludeSemantics(child: backTitle)),
              ),
            ),
            Opacity(
              opacity: CurvedAnimation(
                parent: animation,
                curve: const Interval(0.5, 1.0),
              ).value,
              child: FractionalTranslation(
                translation: Tween<Offset>(
                  begin: const Offset(-0.25, 0.0),
                  end: Offset.zero,
                ).evaluate(animation),
                child: Semantics(
                    label: 'show categories menu',
                    child: ExcludeSemantics(child: frontTitle)),
              ),
            ),
          ],
        )
      ]),
    );
  }
}

/// Builds a Backdrop.
///
/// A Backdrop widget has two layers, front and back. The front layer is shown
/// by default, and slides down to show the back layer, from which a user
/// can make a selection. The user can also configure the titles for when the
/// front or back layer is showing.
class Backdrop extends StatefulWidget {
  final Category currentCategory;
  final Widget frontLayer;
  final Widget backLayer;
  final Widget frontTitle;
  final Widget backTitle;

  const Backdrop({
    required this.currentCategory,
    required this.frontLayer,
    required this.backLayer,
    required this.frontTitle,
    required this.backTitle,
    Key? key,
  }) : super(key: key);

  @override
  _BackdropState createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop>
    with SingleTickerProviderStateMixin {
  final GlobalKey _backdropKey = GlobalKey(debugLabel: 'Backdrop');
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      value: 1.0,
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(Backdrop old) {
    super.didUpdateWidget(old);

    if (widget.currentCategory != old.currentCategory) {
      _toggleBackdropLayerVisibility();
    } else if (!_frontLayerVisible) {
      _controller.fling(velocity: _kFlingVelocity);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _frontLayerVisible {
    final AnimationStatus status = _controller.status;
    return status == AnimationStatus.completed ||
        status == AnimationStatus.forward;
  }

  void _toggleBackdropLayerVisibility() {
    _controller.fling(
        velocity: _frontLayerVisible ? -_kFlingVelocity : _kFlingVelocity);
  }

  Widget _buildStack(BuildContext context, BoxConstraints constraints) {
    const double layerTitleHeight = 48.0;
    final Size layerSize = constraints.biggest;
    final double layerTop = layerSize.height - layerTitleHeight;

    Animation<RelativeRect> layerAnimation = RelativeRectTween(
      begin: RelativeRect.fromLTRB(
          0.0, layerTop, 0.0, layerTop - layerSize.height),
      end: const RelativeRect.fromLTRB(0.0, 0.0, 0.0, 0.0),
    ).animate(_controller.view);

    return Stack(
      key: _backdropKey,
      children: <Widget>[
        ExcludeSemantics(
          child: widget.backLayer,
          excluding: _frontLayerVisible,
        ),
        PositionedTransition(
          rect: layerAnimation,
          child: _FrontLayer(
            onTap: _toggleBackdropLayerVisibility,
            child: widget.frontLayer,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    var appBar = AppBar(
      elevation: 0.0,
      titleSpacing: 0.0,
      title: _BackdropTitle(
        listenable: _controller.view,
        onPress: _toggleBackdropLayerVisibility,
        frontTitle: widget.frontTitle,
        backTitle: widget.backTitle,
      ),
      actions: <Widget>[
        IconButton(
          icon: const Icon(
            Icons.search,
            semanticLabel: 'login',
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const LoginPage()),
            );
          },
        ),
        IconButton(
          icon: const Icon(
            Icons.tune,
            semanticLabel: 'login',
          ),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) => const LoginPage()),
            );
          },
        ),
      ],
    );
    return Scaffold(
      appBar: appBar,
      body: LayoutBuilder(
        builder: _buildStack,
      ),
    );
  }
}

class AsymmetricView extends StatelessWidget {
  final List<Product> products;

  const AsymmetricView({Key? key, required this.products}) : super(key: key);

  List<Widget> _buildColumns(BuildContext context) {
    if (products.isEmpty) {
      return <Container>[];
    }

    /// This will return a list of columns. It will oscillate between the two
    /// kinds of columns. Even cases of the index (0, 2, 4, etc) will be
    /// TwoProductCardColumn and the odd cases will be OneProductCardColumn.
    ///
    /// Each pair of columns will advance us 3 products forward (2 + 1). That's
    /// some kinda awkward math so we use _evenCasesIndex and _oddCasesIndex as
    /// helpers for creating the index of the product list that will correspond
    /// to the index of the list of columns.
    return List.generate(_listItemCount(products.length), (int index) {
      double width = .59 * MediaQuery.of(context).size.width;
      Widget column;
      if (index % 2 == 0) {
        /// Even cases
        int bottom = _evenCasesIndex(index);
        column = TwoProductCardColumn(
            bottom: products[bottom],
            top: products.length - 1 >= bottom + 1
                ? products[bottom + 1]
                : null);
        width += 32.0;
      } else {
        /// Odd cases
        column = OneProductCardColumn(
          product: products[_oddCasesIndex(index)],
        );
      }
      return SizedBox(
        width: width,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: column,
        ),
      );
    }).toList();
  }

  int _evenCasesIndex(int input) {
    /// The operator ~/ is a cool one. It's the truncating division operator. It
    /// divides the number and if there's a remainder / decimal, it cuts it off.
    /// This is like dividing and then casting the result to int. Also, it's
    /// functionally equivalent to floor() in this case.
    return input ~/ 2 * 3;
  }

  int _oddCasesIndex(int input) {
    assert(input > 0);
    return (input / 2).ceil() * 3 - 1;
  }

  int _listItemCount(int totalItems) {
    if (totalItems % 3 == 0) {
      return totalItems ~/ 3 * 2;
    } else {
      return (totalItems / 3).ceil() * 2 - 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(0.0, 34.0, 16.0, 44.0),
      children: _buildColumns(context),
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard(
      {this.imageAspectRatio = 33 / 49, required this.product, Key? key})
      : assert(imageAspectRatio > 0),
        super(key: key);

  final double imageAspectRatio;
  final Product product;

  static const kTextBoxHeight = 65.0;

  @override
  Widget build(BuildContext context) {
    final NumberFormat formatter = NumberFormat.simpleCurrency(
        decimalDigits: 0, locale: Localizations.localeOf(context).toString());
    final ThemeData theme = Theme.of(context);

    final imageWidget = Image.asset(
      product.assetName,
      package: product.assetPackage,
      fit: BoxFit.cover,
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        AspectRatio(
          aspectRatio: imageAspectRatio,
          child: imageWidget,
        ),
        SizedBox(
          height: kTextBoxHeight * MediaQuery.of(context).textScaleFactor,
          width: 121.0,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Text(
                product.name,
                style: theme.textTheme.labelLarge,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 4.0),
              Text(
                formatter.format(product.price),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class TwoProductCardColumn extends StatelessWidget {
  const TwoProductCardColumn({
    required this.bottom,
    this.top,
    Key? key,
  }) : super(key: key);

  final Product bottom;
  final Product? top;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      const spacerHeight = 44.0;

      double heightOfCards = (constraints.biggest.height - spacerHeight) / 2.0;
      double heightOfImages = heightOfCards - ProductCard.kTextBoxHeight;
      double imageAspectRatio = heightOfImages >= 0.0
          ? constraints.biggest.width / heightOfImages
          : 49.0 / 33.0;

      return ListView(
        physics: const ClampingScrollPhysics(),
        children: <Widget>[
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 28.0),
            child: top != null
                ? ProductCard(
                    imageAspectRatio: imageAspectRatio,
                    product: top!,
                  )
                : SizedBox(
                    height: heightOfCards > 0 ? heightOfCards : spacerHeight,
                  ),
          ),
          const SizedBox(height: spacerHeight),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 28.0),
            child: ProductCard(
              imageAspectRatio: imageAspectRatio,
              product: bottom,
            ),
          ),
        ],
      );
    });
  }
}

class OneProductCardColumn extends StatelessWidget {
  const OneProductCardColumn({required this.product, Key? key})
      : super(key: key);

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListView(
      reverse: true,
      physics: const ClampingScrollPhysics(),
      children: <Widget>[
        ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 550,
          ),
          child: ProductCard(
            product: product,
          ),
        ),
        const SizedBox(
          height: 40.0,
        ),
      ],
    );
  }
}

class CutCornersBorder extends OutlineInputBorder {
  const CutCornersBorder({
    BorderSide borderSide = const BorderSide(),
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(2.0)),
    this.cut = 7.0,
    double gapPadding = 2.0,
  }) : super(
            borderSide: borderSide,
            borderRadius: borderRadius,
            gapPadding: gapPadding);

  @override
  CutCornersBorder copyWith({
    BorderSide? borderSide,
    BorderRadius? borderRadius,
    double? gapPadding,
    double? cut,
  }) {
    return CutCornersBorder(
      borderRadius: borderRadius ?? this.borderRadius,
      borderSide: borderSide ?? this.borderSide,
      cut: cut ?? this.cut,
      gapPadding: gapPadding ?? this.gapPadding,
    );
  }

  final double cut;

  @override
  ShapeBorder? lerpFrom(ShapeBorder? a, double t) {
    if (a is CutCornersBorder) {
      final CutCornersBorder outline = a;
      return CutCornersBorder(
        borderRadius: BorderRadius.lerp(outline.borderRadius, borderRadius, t)!,
        borderSide: BorderSide.lerp(outline.borderSide, borderSide, t),
        cut: cut,
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpFrom(a, t);
  }

  @override
  ShapeBorder? lerpTo(ShapeBorder? b, double t) {
    if (b is CutCornersBorder) {
      final CutCornersBorder outline = b;
      return CutCornersBorder(
        borderRadius: BorderRadius.lerp(borderRadius, outline.borderRadius, t)!,
        borderSide: BorderSide.lerp(borderSide, outline.borderSide, t),
        cut: cut,
        gapPadding: outline.gapPadding,
      );
    }
    return super.lerpTo(b, t);
  }

  Path _notchedCornerPath(Rect center,
      [double start = 0.0, double extent = 0.0]) {
    final Path path = Path();
    if (start > 0.0 || extent > 0.0) {
      path.relativeMoveTo(extent + start, center.top);
      _notchedSidesAndBottom(center, path);
      path
        ..lineTo(center.left + cut, center.top)
        ..lineTo(start, center.top);
    } else {
      path.moveTo(center.left + cut, center.top);
      _notchedSidesAndBottom(center, path);
      path.lineTo(center.left + cut, center.top);
    }
    return path;
  }

  Path _notchedSidesAndBottom(Rect center, Path path) {
    return path
      ..lineTo(center.right - cut, center.top)
      ..lineTo(center.right, center.top + cut)
      ..lineTo(center.right, center.top + center.height - cut)
      ..lineTo(center.right - cut, center.top + center.height)
      ..lineTo(center.left + cut, center.top + center.height)
      ..lineTo(center.left, center.top + center.height - cut)
      ..lineTo(center.left, center.top + cut);
  }

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    double? gapStart,
    double gapExtent = 0.0,
    double gapPercentage = 0.0,
    TextDirection? textDirection,
  }) {
    assert(gapPercentage >= 0.0 && gapPercentage <= 1.0);

    final Paint paint = borderSide.toPaint();
    final RRect outer = borderRadius.toRRect(rect);
    if (gapStart == null || gapExtent <= 0.0 || gapPercentage == 0.0) {
      canvas.drawPath(_notchedCornerPath(outer.middleRect), paint);
    } else {
      final double extent =
          lerpDouble(0.0, gapExtent + gapPadding * 2.0, gapPercentage)!;
      switch (textDirection) {
        case TextDirection.RTL:
          {
            final Path path = _notchedCornerPath(
                outer.middleRect, gapStart + gapPadding - extent, extent);
            canvas.drawPath(path, paint);
            break;
          }
        case TextDirection.LTR:
          {
            final Path path = _notchedCornerPath(
                outer.middleRect, gapStart - gapPadding, extent);
            canvas.drawPath(path, paint);
            break;
          }

        case TextDirection.UNKNOWN:
          // TODO: Handle this case.
          break;
      }
    }
    super.paint(canvas, rect);
  }
}
