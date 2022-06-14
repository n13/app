import 'package:app/common/components/jumpToLink.dart';
import 'package:app/common/consts.dart';
import 'package:app/common/types/pluginDisabled.dart';
import 'package:app/pages/account/accountTypeSelectPage.dart';
import 'package:app/service/index.dart';
import 'package:app/utils/Utils.dart';
import 'package:app/utils/i18n/index.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:polkawallet_sdk/plugin/index.dart';
import 'package:polkawallet_sdk/storage/types/keyPairData.dart';
import 'package:polkawallet_sdk/utils/i18n.dart';
import 'package:polkawallet_ui/components/v3/addressIcon.dart';
import 'package:polkawallet_ui/components/v3/back.dart';
import 'package:polkawallet_ui/components/v3/roundedCard.dart';
import 'package:polkawallet_ui/utils/format.dart';
import 'package:polkawallet_ui/utils/i18n.dart';
import 'package:polkawallet_ui/utils/index.dart';

class NetworkSelectPage extends StatefulWidget {
  NetworkSelectPage(
      this.service, this.plugins, this.disabledPlugins, this.changeNetwork);

  static final String route = '/network';

  final AppService service;
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;

  @override
  _NetworkSelectPageState createState() => _NetworkSelectPageState();
}

class _NetworkSelectPageState extends State<NetworkSelectPage> {
  bool _isEvm = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
          title: Text(I18n.of(context)
              .getDic(i18n_full_dic_app, 'profile')['setting.network']),
          centerTitle: true,
          leading: BackBtn(),
          actions: [
            GestureDetector(
                onTap: () {
                  setState(() {
                    _isEvm = !_isEvm;
                  });
                },
                child: Center(
                  child: Padding(
                      padding: EdgeInsets.only(right: 16.w),
                      child: Image.asset(
                          "assets/images/${_isEvm ? "evm" : "substrate"}.png",
                          height: 31)),
                ))
          ],
          elevation: 2),
      body: NetworkSelectWidget(
        widget.service,
        widget.plugins,
        widget.disabledPlugins,
        widget.changeNetwork,
        isEvm: _isEvm,
      ),
    );
  }
}

class NetworkSelectWidget extends StatefulWidget {
  NetworkSelectWidget(
      this.service, this.plugins, this.disabledPlugins, this.changeNetwork,
      {Key key, this.isEvm})
      : super(key: key);

  final AppService service;
  final List<PolkawalletPlugin> plugins;
  final List<PluginDisabled> disabledPlugins;
  final Future<void> Function(PolkawalletPlugin) changeNetwork;
  bool isEvm = false;

  @override
  State<NetworkSelectWidget> createState() => _NetworkSelectWidgetState();
}

class _NetworkSelectWidgetState extends State<NetworkSelectWidget> {
  PluginDisabled _pluginDisabledSelected;
  PolkawalletPlugin _selectedNetwork;
  bool _networkChanging = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      setState(() {
        _selectedNetwork = widget.service.plugin;
      });
    });
  }

  Future<void> _onSelect(KeyPairData i) async {
    bool isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name;
    if (i.address != widget.service.keyring.current.address ||
        !isCurrentNetwork) {
      /// set current account
      widget.service.keyring.setCurrent(i);

      if (!isCurrentNetwork) {
        /// set new network and reload web view
        await _reloadNetwork();

        _selectedNetwork.changeAccount(i);
      } else {
        widget.service.plugin.changeAccount(i);
      }

      widget.service.store.assets.loadCache(i, _selectedNetwork.basic.name);
    }
    Navigator.of(context).pop(_selectedNetwork);
  }

  Future<void> _reloadNetwork() async {
    setState(() {
      _networkChanging = true;
    });
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: Text(
              I18n.of(context).getDic(i18n_full_dic_ui, 'common')['loading']),
          content: Container(height: 64, child: CupertinoActivityIndicator()),
        );
      },
    );
    await widget.changeNetwork(_selectedNetwork);

    if (mounted) {
      Navigator.of(context).pop();
      setState(() {
        _networkChanging = false;
      });
    }
  }

  Future<void> _onCreateAccount(int step) async {
    bool isCurrentNetwork =
        _selectedNetwork.basic.name == widget.service.plugin.basic.name;
    if (!isCurrentNetwork) {
      await _reloadNetwork();
    }
    Navigator.of(context)
        .pushNamed(AccountTypeSelectPage.route, arguments: step);
  }

  Widget netWorkItem(Function() onTap, Widget icon) {
    return Container(
        width: 64.w,
        height: 74.h,
        child: Center(
          child: GestureDetector(
              onTap: onTap,
              child: Container(
                  padding: EdgeInsets.fromLTRB(10, 10, 12, 12),
                  child: SizedBox(child: icon, height: 26, width: 26),
                  decoration: BoxDecoration(
                      image: DecorationImage(
                          image: AssetImage(
                              "assets/images/selectWallet_unselect.png"),
                          fit: BoxFit.fill)))),
        ));
  }

  List<Widget> _buildAccountList() {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    final name =
        _selectedNetwork?.basic?.name ?? _pluginDisabledSelected?.name ?? '';

    /// first item is current account
    List<KeyPairData> accounts = [widget.service.keyring.current];

    /// add optional accounts
    accounts.addAll(widget.service.keyring.optionals);

    final List<Widget> accountWidgets = [];
    if (_selectedNetwork != null) {
      accountWidgets.addAll(accounts.map((i) {
        final bool isCurrentNetwork =
            _selectedNetwork.basic.name == widget.service.plugin.basic.name;
        final addressMap = widget.service.keyring.store
            .pubKeyAddressMap[_selectedNetwork.basic.ss58.toString()];
        final address = addressMap != null
            ? addressMap[i.pubKey]
            : widget.service.keyring.current.address;
        final String accIndex = isCurrentNetwork &&
                i.indexInfo != null &&
                i.indexInfo['accountIndex'] != null
            ? '${i.indexInfo['accountIndex']}\n'
            : '';
        final isCurrent = isCurrentNetwork &&
            i.address == widget.service.keyring.current.address;
        return Column(
          children: [
            Container(
              color: Colors.transparent,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: AddressIcon(address, svg: i.icon),
                title: Text(
                  UI.accountName(context, i),
                  style: Theme.of(context).textTheme.headline5,
                ),
                subtitle: Text('$accIndex${Fmt.address(address)}',
                    maxLines: 2,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: Color(0xFF565554),
                        fontFamily: "SF_Pro")),
                trailing: Image.asset(
                  "assets/images/${isCurrent ? "icon_circle_select.png" : "icon_circle_unselect.png"}",
                  fit: BoxFit.contain,
                  width: 16.w,
                ),
                onTap: _networkChanging ? null : () => _onSelect(i),
              ),
            ),
            Divider(
              height: 1,
            )
          ],
        );
      }).toList());
    }

    final List<Widget> res = [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            name.toUpperCase(),
            style: Theme.of(context).textTheme.headline3?.copyWith(
                fontSize: 36, fontWeight: FontWeight.bold, height: 1.0),
          ),
        ],
      ),
      Visibility(
          visible: plugin_from_community.indexOf(name) > -1,
          child: _CommunityPluginNote(name, false)),
      Expanded(
          child: Padding(
              padding: EdgeInsets.only(top: 10, bottom: 10),
              child: SingleChildScrollView(
                child: Column(
                  children: accountWidgets,
                ),
              ))),
      Column(
        children: [
          GestureDetector(
            child: Container(
                width: double.infinity,
                child: RoundedCard(
                    color: Color(0xFFEBEAE8),
                    margin: EdgeInsets.only(top: 4.h, bottom: 16.h),
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: SvgPicture.asset(
                            "assets/images/icon_add.svg",
                            width: 16.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          dic['create'],
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ))),
            onTap: () => _onCreateAccount(0),
          ),
          Container(
            width: 16.h,
          ),
          GestureDetector(
            child: Container(
                width: double.infinity,
                child: RoundedCard(
                    color: Color(0xFFEBEAE8),
                    margin: EdgeInsets.only(bottom: 16.h),
                    padding: EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(right: 4.w),
                          child: SvgPicture.asset(
                            "assets/images/icon_add.svg",
                            width: 16.h,
                            fit: BoxFit.contain,
                          ),
                        ),
                        Text(
                          dic['import'],
                          style: Theme.of(context).textTheme.headline4,
                        )
                      ],
                    ))),
            onTap: () => _onCreateAccount(1),
          )
        ],
      ),
    ];

    return res;
  }

  List<Widget> _buildPluginDisabled() {
    return [
      Text(
        _pluginDisabledSelected.name.toUpperCase(),
        style: Theme.of(context).textTheme.headline3,
      ),
      _CommunityPluginNote(_pluginDisabledSelected.name, true),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        // left side bar
        Padding(
            padding: EdgeInsets.only(top: 20.h, right: 15),
            child: Stack(
              children: [
                Container(
                  width: 64.w,
                  // color: Theme.of(context).cardColor,
                  decoration: BoxDecoration(
                    color: Color(0xFFF3F1ED),
                    borderRadius:
                        BorderRadius.only(topRight: Radius.circular(24.w)),
                    boxShadow: [
                      BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 3.0,
                          spreadRadius: 1.0,
                          offset: Offset(2.0, 2.0))
                    ],
                  ),
                ),
                Padding(
                    padding: EdgeInsets.only(top: 16.h, bottom: 10.h),
                    child: SingleChildScrollView(
                        physics: BouncingScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: EdgeInsets.only(left: 12.w, right: 8.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Image.asset(
                                    'assets/images/logo_text_line2.png',
                                    width: 32.w,
                                  ),
                                  Container(
                                    margin:
                                        EdgeInsets.only(top: 8.h, bottom: 8.h),
                                    height: 4.h,
                                    width: 34.w,
                                    decoration: BoxDecoration(
                                        border: Border.symmetric(
                                            horizontal: BorderSide(
                                                color: Color(0xFFCCCAC6)))),
                                  )
                                ],
                              ),
                            ),
                            ...widget.plugins.map((e) {
                              final isCurrent =
                                  e.basic.name == _selectedNetwork?.basic?.name;
                              return isCurrent
                                  ? _NetworkItemActive(icon: e.basic.icon)
                                  : netWorkItem(() {
                                      if (!isCurrent) {
                                        setState(() {
                                          _selectedNetwork = e;
                                          _pluginDisabledSelected = null;
                                        });
                                      }
                                    },
                                      isCurrent
                                          ? e.basic.icon
                                          : Image.asset(
                                              'assets/images/plugins/logo_${e.basic.name.toLowerCase()}_grey.png'));
                            }).toList(),
                            ...widget.disabledPlugins.map((e) {
                              final isCurrent =
                                  e.name == _pluginDisabledSelected?.name;
                              return isCurrent
                                  ? _NetworkItemActive(icon: e.icon)
                                  : netWorkItem(() {
                                      if (_pluginDisabledSelected?.name !=
                                          e.name) {
                                        setState(() {
                                          _pluginDisabledSelected = e;
                                          _selectedNetwork = null;
                                        });
                                      }
                                    }, e.icon);
                            }).toList()
                          ],
                          // children: sideBar,
                        ))),
              ],
            )),
        Expanded(
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 112,
              height: 23.5,
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius:
                    BorderRadius.only(bottomLeft: Radius.circular(20.w)),
                gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    stops: [0.2, 0.5, 1],
                    colors: widget.isEvm
                        ? [
                            Color(0xFF1DCA80),
                            Color(0xFF10B95D),
                            Color(0xFF9ABD16)
                          ]
                        : [
                            Color(0xFFFF4C3B),
                            Color(0xFFE40C5B),
                            Color(0xFF645AFF)
                          ]),
              ),
            ),
            Expanded(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: _pluginDisabledSelected == null
                          ? _buildAccountList()
                          : _buildPluginDisabled(),
                    ))),
          ],
        ))
      ],
    );
  }
}

class _NetworkItemActive extends StatelessWidget {
  _NetworkItemActive({this.icon});
  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        Padding(
            padding: EdgeInsets.only(left: 7),
            child: Image.asset(
              "assets/images/selectWallet_select_bg.png",
              fit: BoxFit.contain,
              width: 65.w,
            )),
        Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(child: icon, height: 40, width: 40),
            decoration: BoxDecoration(
                image: DecorationImage(
                    image: AssetImage("assets/images/selectWallet_select.png"),
                    fit: BoxFit.fill)))
      ],
    );
  }
}

class _CommunityPluginNote extends StatelessWidget {
  _CommunityPluginNote(this.pluginName, this.disabled);
  final String pluginName;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final dic = I18n.of(context).getDic(i18n_full_dic_app, 'account');
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(
                dic['plugin.note'] +
                    pluginName.toUpperCase() +
                    dic['plugin.team'],
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.headline6,
              )),
              Padding(
                  padding: EdgeInsets.only(left: 3),
                  child: SvgPicture.asset(
                      'assets/images/public/github_logo.svg',
                      width: 16)),
              JumpToLink(
                plugin_github_links[pluginName],
                text: '',
              )
            ],
          ),
          Visibility(visible: disabled, child: Divider(height: 1)),
          Visibility(visible: disabled, child: Text(dic['plugin.disable'])),
        ],
      ),
    );
  }
}
