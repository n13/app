import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/networkSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';

class NodeSelectPage extends StatefulWidget {
  NodeSelectPage(
      this.service, this.plugins, this.changeNetwork, this.disabledPlugins,
      {Key key})
      : super(key: key);

  final List<PolkawalletPlugin> plugins;
  final AppService service;

  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  static final String route = '/nodeSelect';

  @override
  _NodeSelectPageState createState() => _NodeSelectPageState();
}

class _NodeSelectPageState extends State<NodeSelectPage> {
  int expansionIndex = -1;
  bool _isEvm = false;

  @override
  void initState() {
    super.initState();
    expansionIndex = widget.plugins.indexWhere(
        (element) => element.basic.name == widget.service.plugin.basic.name);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30), topRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(bottom: 7.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30), topRight: Radius.circular(30)),
              color: Color(0xFFF0ECE6),
              boxShadow: [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 4.0,
                  spreadRadius: 0.0,
                  offset: Offset(
                    0.0,
                    2.0,
                  ),
                )
              ],
            ),
            height: 48.h,
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Text(
                      I18n.of(context).getDic(
                          i18n_full_dic_app, 'assets')["v3.changeNetwork"],
                      style: Theme.of(context)
                          .textTheme
                          .headline5
                          .copyWith(fontWeight: FontWeight.w600)),
                ),
                Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 15.w),
                        child: Icon(
                          Icons.close,
                          color: Theme.of(context).disabledColor,
                          size: 15,
                        ),
                      ),
                    )),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _isEvm = !_isEvm;
                      });
                    },
                    child: Padding(
                        padding: EdgeInsets.only(right: 16.w),
                        child: Image.asset(
                            "assets/images/${_isEvm ? "evm" : "substrate"}.png",
                            height: 31)),
                  ),
                )
              ],
            ),
          ),
          Expanded(
              child: NetworkSelectWidget(
            widget.service,
            widget.plugins,
            widget.disabledPlugins,
            widget.changeNetwork,
            isEvm: _isEvm,
          ))
        ],
      ),
    );
  }
}
