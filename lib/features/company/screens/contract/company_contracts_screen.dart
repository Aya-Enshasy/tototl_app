import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../payments/services/payment_service.dart';
import '../../controllers/company_job_controller.dart';
import '../../services/company_job_service.dart';
import '../../../payments/models/payment_model.dart';
import '../../../payments/screens/payment_history_screen.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_contract_model.dart';
import '../../services/company_contract_service.dart';
import 'company_contract_detail_screen.dart';

class CompanyContractsScreen extends StatefulWidget {
  const CompanyContractsScreen({super.key});

  @override
  State<CompanyContractsScreen> createState() => _CompanyContractsScreenState();
}

class _CompanyContractsScreenState extends State<CompanyContractsScreen> {
  late final CompanyContractController _controller;
  late final CompanyJobController _jobController;
  bool _firstLoad = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    final apiClient = ApiClient();

    _controller = CompanyContractController(
      CompanyContractService(apiClient),
    );

    _jobController = CompanyJobController(
      CompanyJobService(apiClient),
    );

    unawaited(_load());
  }

  Future<void> _load() async {
    await Future.wait<dynamic>([
      _controller.loadContracts(
        status: _filter == 'all'
            ? null
            : _filter,
      ),
      _jobController.loadCompanyApplicants(
        perPage: 100,
      ),
    ]);

    if (!mounted) return;

    setState(() => _firstLoad = false);
  }

  dynamic _contextFor(
      CompanyContractModel contract,
      ) {
    for (final item in _jobController.companyApplicants) {
      if (contract.jobApplicationId > 0 &&
          item.application.id ==
              contract.jobApplicationId) {
        return item;
      }
    }

    for (final item in _jobController.companyApplicants) {
      if (item.application.jobPostingId ==
          contract.jobPostingId &&
          item.application.pilotProfileId ==
              contract.pilotProfileId) {
        return item;
      }
    }

    return null;
  }

  Future<void> _openPayments() async {
    HapticFeedback.selectionClick();

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
        const PaymentHistoryScreen(
          audience: PaymentAudience.company,
        ),
      ),
    );
  }

  Future<void> _changeFilter(String value) async {
    if (_filter == value || _controller.isLoading) return;
    HapticFeedback.selectionClick();
    setState(() => _filter = value);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            _topBar(),
            _filterBar(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar() => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 16, 8),
    child: Row(
      children: [
        _circleButton(Icons.arrow_back_ios_new_rounded, () => Navigator.pop(context)),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Contracts', style: TextStyle(color: AppColors.navy, fontSize: 18, fontWeight: FontWeight.w900)),
              SizedBox(height: 3),
              Text('Manage contract lifecycle & funding', style: TextStyle(color: AppColors.grey, fontSize: 10.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        _circleButton(
          Icons.account_balance_wallet_outlined,
          _openPayments,
        ),
        const SizedBox(width: 7),
        _circleButton(
          Icons.refresh_rounded,
          _controller.isLoading ? null : _load,
        ),
      ],
    ),
  );

  Widget _filterBar() {
    const values = <String>['all','pending','accepted','active','in_progress','submitted','completed'];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 7),
        itemBuilder: (_, i) {
          final value = values[i];
          final selected = _filter == value;
          return ChoiceChip(
            selected: selected,
            onSelected: (_) => _changeFilter(value),
            label: Text(_pretty(value)),
            labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy, fontSize: 10.5, fontWeight: FontWeight.w800),
            selectedColor: AppColors.navy,
            backgroundColor: Colors.white,
            side: const BorderSide(color: AppColors.cardBorder),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_firstLoad && _controller.isLoading) {
      return ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => Container(height: 150, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.cardBorder))),
      );
    }
    if (_controller.errorMessage != null && _controller.contracts.isEmpty) {
      return _centerState(Icons.cloud_off_rounded, 'Couldn’t load contracts', _controller.errorMessage!, 'Retry', _load);
    }
    if (_controller.contracts.isEmpty) {
      return _centerState(Icons.description_outlined, 'No contracts yet', 'Contracts will appear here once created.', null, null);
    }
    return RefreshIndicator(
      color: AppColors.blue,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
        itemCount: _controller.contracts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 11),
        itemBuilder: (_, i) => _contractCard(_controller.contracts[i]),
      ),
    );
  }

  Widget _contractCard(
      CompanyContractModel c,
      ) {
    final visual = _visual(c.status);
    final contextItem = _contextFor(c);

    final job = contextItem?.jobPosting;
    final application =
        contextItem?.application;
    final pilot =
        application?.pilotProfile;

    final title =
    job?.title.trim().isNotEmpty == true
        ? job!.title.trim()
        : 'Mission';

    final pilotName =
    pilot?.displayName.trim().isNotEmpty ==
        true
        ? pilot!.displayName.trim()
        : 'Pilot';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius:
        BorderRadius.circular(22),
        onTap: () async {
          final changed =
          await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  CompanyContractDetailScreen(
                    contractId: c.id,
                    initialContract: c,
                    initialJob: job,
                    initialApplication:
                    application,
                  ),
            ),
          );

          if (changed == true) {
            await _load();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius:
            BorderRadius.circular(22),
            border: Border.all(
              color: AppColors.cardBorder,
            ),
            boxShadow: [
              BoxShadow(
                color:
                AppColors.navy.withOpacity(.025),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: visual.$2,
                      borderRadius:
                      BorderRadius.circular(13),
                    ),
                    child: Icon(
                      Icons.description_outlined,
                      color: visual.$1,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.navy,
                            fontWeight:
                            FontWeight.w900,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          pilotName,
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.grey,
                            fontSize: 10.6,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: visual.$2,
                      borderRadius:
                      BorderRadius.circular(20),
                    ),
                    child: Text(
                      c.statusLabel,
                      style: TextStyle(
                        color: visual.$1,
                        fontSize: 9.5,
                        fontWeight:
                        FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _metric(
                      'Amount',
                      c.amountLabel,
                      Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metric(
                      'Payment',
                      c.paymentTypeLabel,
                      Icons
                          .account_balance_wallet_outlined,
                    ),
                  ),
                ],
              ),
              if (c.isAccepted) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius:
                    BorderRadius.circular(13),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.bolt_rounded,
                        color: AppColors.green,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'Ready to fund — open mission',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 10.8,
                            fontWeight:
                            FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _metric(String label,String value,IconData icon)=>Container(padding:const EdgeInsets.all(10),decoration:BoxDecoration(color:AppColors.bg,borderRadius:BorderRadius.circular(13)),child:Row(children:[Icon(icon,size:15,color:AppColors.blue),const SizedBox(width:7),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(label,style:const TextStyle(color:AppColors.grey,fontSize:9.2)),const SizedBox(height:2),Text(value,maxLines:1,overflow:TextOverflow.ellipsis,style:const TextStyle(color:AppColors.navy,fontSize:10.8,fontWeight:FontWeight.w800))]))]));

  Widget _centerState(IconData icon,String title,String text,String? action,Future<void> Function()? onTap)=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[Container(width:64,height:64,decoration:BoxDecoration(color:AppColors.blueBg,borderRadius:BorderRadius.circular(20)),child:Icon(icon,color:AppColors.blue,size:29)),const SizedBox(height:14),Text(title,style:const TextStyle(color:AppColors.navy,fontSize:16,fontWeight:FontWeight.w900)),const SizedBox(height:6),Text(text,textAlign:TextAlign.center,style:const TextStyle(color:AppColors.grey,fontSize:11.5,height:1.45)),if(action!=null&&onTap!=null)...[const SizedBox(height:14),FilledButton(onPressed:()=>onTap(),child:Text(action))]])));
  Widget _circleButton(IconData icon,VoidCallback? onTap)=>Material(color:Colors.white,shape:const CircleBorder(),child:InkWell(onTap:onTap,customBorder:const CircleBorder(),child:Container(width:42,height:42,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:AppColors.cardBorder)),child:Icon(icon,color:onTap==null?AppColors.lightGrey:AppColors.navy,size:18))));
}

(Color, Color) _visual(String status) {
  switch (status.trim().toLowerCase()) {
    case 'accepted': return (AppColors.green, AppColors.greenBg);
    case 'active': return (AppColors.blue, AppColors.blueBg);
    case 'completed': return (AppColors.green, AppColors.greenBg);
    case 'cancelled': case 'terminated': case 'rejected': return (AppColors.red, AppColors.redBg);
    default: return (AppColors.orange, AppColors.orangeBg);
  }
}
String _pretty(String value)=>value.split(RegExp(r'[_\s-]+')).where((e)=>e.isNotEmpty).map((e)=>'${e[0].toUpperCase()}${e.substring(1).toLowerCase()}').join(' ');
