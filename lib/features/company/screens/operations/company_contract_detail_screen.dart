import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../controllers/company_contract_controller.dart';
import '../../models/company_contract_model.dart';
import '../../services/company_contract_service.dart';
import 'company_contracts_screen.dart';

class CompanyContractDetailScreen extends StatefulWidget {
  const CompanyContractDetailScreen({
    super.key,
    required this.contractId,
    this.initialContract,
  });
  final int contractId;
  final CompanyContractModel? initialContract;

  @override
  State<CompanyContractDetailScreen> createState() => _CompanyContractDetailScreenState();
}

class _CompanyContractDetailScreenState extends State<CompanyContractDetailScreen> {
  late final CompanyContractController _controller;
  CompanyContractModel? _contract;
  bool _initialLoading = true;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _controller = CompanyContractController(CompanyContractService(ApiClient()));
    _contract = widget.initialContract;
    if (_contract != null) _controller.seed(_contract!);
    unawaited(_load());
  }

  Future<void> _load() async {
    final ok = await _controller.loadContract(widget.contractId);
    if (!mounted) return;
    setState(() {
      if (ok) _contract = _controller.selectedContract;
      _initialLoading = false;
    });
  }

  Future<void> _fund() async {
    final contract = _contract;
    if (contract == null || !contract.canFund || _controller.isFunding) return;
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Row(children:[Icon(Icons.account_balance_wallet_rounded,color:AppColors.green),SizedBox(width:9),Expanded(child:Text('Fund contract',style:TextStyle(color:AppColors.navy,fontWeight:FontWeight.w900,fontSize:17)))]),
        content: Text('Confirm funding ${contract.amountLabel}. On success the contract becomes Active and the pilot can continue to the work stage.',style:const TextStyle(color:AppColors.grey,fontSize:12.2,height:1.5)),
        actions: [
          TextButton(onPressed:()=>Navigator.pop(dialogContext,false),child:const Text('Cancel')),
          FilledButton(style:FilledButton.styleFrom(backgroundColor:AppColors.green),onPressed:()=>Navigator.pop(dialogContext,true),child:const Text('Fund Contract')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {});
    final updated = await _controller.fundContract(contract.id);
    if (!mounted) return;
    if (updated == null) {
      setState(() {});
      _snack(_controller.actionErrorMessage ?? 'Unable to fund this contract.', error: true);
      return;
    }
    setState(() { _contract = updated; _changed = true; });
    _snack('Contract funded successfully. Contract is now ${updated.statusLabel}.');
  }

  void _back()=>Navigator.pop(context,_changed);

  @override
  Widget build(BuildContext context) {
    final contract = _contract;
    return PopScope(
      canPop:false,
      onPopInvokedWithResult:(didPop,result){ if(!didPop) _back(); },
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(child: Column(children:[_topBar(),Expanded(child:_initialLoading&&contract==null?_loading():contract==null?_error():_content(contract))])),
        bottomNavigationBar: contract?.canFund==true ? _fundBar(contract!) : null,
      ),
    );
  }

  Widget _topBar()=>Padding(padding:const EdgeInsets.fromLTRB(11,9,13,7),child:Row(children:[_circle(Icons.arrow_back_ios_new_rounded,_back),const SizedBox(width:11),const Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text('Contract Details',style:TextStyle(color:AppColors.navy,fontSize:16.5,fontWeight:FontWeight.w900)),SizedBox(height:3),Text('Lifecycle, funding & payment status',style:TextStyle(color:AppColors.grey,fontSize:9.8,fontWeight:FontWeight.w600))])),_circle(Icons.refresh_rounded,_controller.isLoadingDetail?null:_load)]));

  Widget _content(CompanyContractModel c) {
    final visual=_visual(c.status);
    return RefreshIndicator(color:AppColors.blue,onRefresh:_load,child:ListView(physics:const AlwaysScrollableScrollPhysics(parent:BouncingScrollPhysics()),padding:const EdgeInsets.fromLTRB(16,8,16,32),children:[
      Container(padding:const EdgeInsets.all(19),decoration:BoxDecoration(gradient:const LinearGradient(begin:Alignment.topLeft,end:Alignment.bottomRight,colors:[Color(0xFF071D39),Color(0xFF0B4357),Color(0xFF0D8799)]),borderRadius:BorderRadius.circular(27),boxShadow:[BoxShadow(color:AppColors.navy.withOpacity(.14),blurRadius:28,offset:const Offset(0,12))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
        Row(children:[Container(padding:const EdgeInsets.symmetric(horizontal:10,vertical:6),decoration:BoxDecoration(color:Colors.white.withOpacity(.10),borderRadius:BorderRadius.circular(20)),child:Text(c.statusLabel,style:const TextStyle(color:Colors.white,fontSize:10,fontWeight:FontWeight.w900))),const Spacer(),Text('#${c.id}',style:TextStyle(color:Colors.white.withOpacity(.55),fontSize:11,fontWeight:FontWeight.w700))]),
        const SizedBox(height:22),Text(c.amountLabel,style:const TextStyle(color:Colors.white,fontSize:27,fontWeight:FontWeight.w900,letterSpacing:-.4)),const SizedBox(height:5),Text('${c.paymentTypeLabel} payment • Job #${c.jobPostingId}',style:TextStyle(color:Colors.white.withOpacity(.70),fontSize:11.5,fontWeight:FontWeight.w600)),
        if(c.isAccepted)...[const SizedBox(height:17),Container(width:double.infinity,padding:const EdgeInsets.all(11),decoration:BoxDecoration(color:Colors.white.withOpacity(.08),borderRadius:BorderRadius.circular(14)),child:const Row(children:[Icon(Icons.bolt_rounded,color:Color(0xFF7BE4D8),size:18),SizedBox(width:8),Expanded(child:Text('Pilot accepted. This contract is ready for company funding.',style:TextStyle(color:Colors.white,fontSize:10.8,height:1.4,fontWeight:FontWeight.w700))) ]))]
      ])),
      const SizedBox(height:13),_section('Contract snapshot',Icons.description_outlined,Column(children:[_row('Application','#${c.jobApplicationId}'),_row('Pilot','#${c.pilotProfileId}'),_row('Start',_date(c.startDate)),if(c.endDate!=null)_row('End',_date(c.endDate)),_row('Payment type',c.paymentTypeLabel)])),
      const SizedBox(height:13),_section('Lifecycle',Icons.route_rounded,_timeline(c)),
      if(c.terms.trim().isNotEmpty)...[const SizedBox(height:13),_section('Terms',Icons.gavel_outlined,Text(c.terms,style:const TextStyle(color:AppColors.text,fontSize:12,height:1.55)))],
      const SizedBox(height:13),_section('Payment',Icons.account_balance_wallet_outlined,_payment(c)),
      const SizedBox(height:13),OutlinedButton.icon(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const CompanyContractsScreen())),icon:const Icon(Icons.list_alt_rounded),label:const Text('All Contracts'),style:OutlinedButton.styleFrom(minimumSize:const Size(double.infinity,50),foregroundColor:AppColors.navy,side:const BorderSide(color:AppColors.cardBorder),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)))),
    ]));
  }

  Widget _timeline(CompanyContractModel c) {
    final steps = <(String, String)>[('pending','Proposed'),('accepted','Pilot accepted'),('active','Funded / Active'),('in_progress','Work started'),('submitted','Submitted'),('completed','Completed')];
    const order={'pending':0,'accepted':1,'active':2,'in_progress':3,'submitted':4,'completed':5};
    final current=order[c.normalizedStatus]??0;
    return Column(children:List.generate(steps.length,(i){final done=i<=current&&!c.isRejected&&!c.isCancelled&&!c.isTerminated;return Padding(padding:EdgeInsets.only(bottom:i==steps.length-1?0:10),child:Row(children:[Container(width:28,height:28,decoration:BoxDecoration(color:done?AppColors.greenBg:AppColors.bg,shape:BoxShape.circle,border:Border.all(color:done?AppColors.green.withOpacity(.25):AppColors.cardBorder)),child:Icon(done?Icons.check_rounded:Icons.circle_outlined,size:14,color:done?AppColors.green:AppColors.lightGrey)),const SizedBox(width:9),Expanded(child:Text(steps[i].$2,style:TextStyle(color:done?AppColors.navy:AppColors.grey,fontSize:11.2,fontWeight:done?FontWeight.w800:FontWeight.w600)))]));}));
  }

  Widget _payment(CompanyContractModel c) {
    final p=c.latestPayment;
    if(p==null){return Container(width:double.infinity,padding:const EdgeInsets.all(12),decoration:BoxDecoration(color:c.isAccepted?AppColors.greenBg:AppColors.bg,borderRadius:BorderRadius.circular(14)),child:Row(children:[Icon(c.isAccepted?Icons.account_balance_wallet_rounded:Icons.hourglass_top_rounded,color:c.isAccepted?AppColors.green:AppColors.grey,size:18),const SizedBox(width:8),Expanded(child:Text(c.isAccepted?'Ready to fund ${c.amountLabel}. Tap Fund Contract below.':'No payment record returned yet.',style:TextStyle(color:c.isAccepted?AppColors.green:AppColors.grey,fontSize:11,fontWeight:FontWeight.w700,height:1.4)))]));}
    return Column(children:[_row('Status',p.statusLabel),_row('Amount','${p.amount} ${p.currency}'),if(p.provider.isNotEmpty)_row('Provider',p.provider),if(p.transactionReference.isNotEmpty)_row('Reference',p.transactionReference),if(p.fundedAt!=null)_row('Funded',_dateTime(p.fundedAt)),if(p.failureReason.isNotEmpty)_row('Failure',p.failureReason)]);
  }

  Widget _fundBar(CompanyContractModel c)=>SafeArea(top:false,child:Container(padding:const EdgeInsets.fromLTRB(16,10,16,13),decoration:BoxDecoration(color:Colors.white,border:const Border(top:BorderSide(color:AppColors.cardBorder)),boxShadow:[BoxShadow(color:AppColors.navy.withOpacity(.06),blurRadius:24,offset:const Offset(0,-7))]),child:SizedBox(height:54,child:FilledButton.icon(onPressed:_controller.isFunding?null:_fund,style:FilledButton.styleFrom(backgroundColor:AppColors.green,foregroundColor:Colors.white,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(17))),icon:_controller.isFunding?const SizedBox(width:18,height:18,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)):const Icon(Icons.account_balance_wallet_rounded,size:19),label:Text(_controller.isFunding?'Funding...':'Fund Contract • ${c.amountLabel}',style:const TextStyle(fontSize:13,fontWeight:FontWeight.w900))))));
  Widget _section(String title,IconData icon,Widget child)=>Container(width:double.infinity,padding:const EdgeInsets.all(16),decoration:BoxDecoration(color:Colors.white,borderRadius:BorderRadius.circular(20),border:Border.all(color:AppColors.cardBorder),boxShadow:[BoxShadow(color:AppColors.navy.withOpacity(.022),blurRadius:18,offset:const Offset(0,6))]),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Container(width:34,height:34,decoration:BoxDecoration(color:AppColors.blueBg,borderRadius:BorderRadius.circular(11)),child:Icon(icon,color:AppColors.blue,size:17)),const SizedBox(width:9),Text(title,style:const TextStyle(color:AppColors.navy,fontSize:13,fontWeight:FontWeight.w900))]),const SizedBox(height:14),child]));
  Widget _row(String l,String v)=>Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(crossAxisAlignment:CrossAxisAlignment.start,children:[SizedBox(width:106,child:Text(l,style:const TextStyle(color:AppColors.grey,fontSize:10.5,fontWeight:FontWeight.w600))),Expanded(child:Text(v,textAlign:TextAlign.right,style:const TextStyle(color:AppColors.navy,fontSize:11,fontWeight:FontWeight.w800))) ]));
  Widget _circle(IconData icon,VoidCallback? tap)=>Material(color:Colors.white,shape:const CircleBorder(),child:InkWell(onTap:tap,customBorder:const CircleBorder(),child:Container(width:42,height:42,decoration:BoxDecoration(shape:BoxShape.circle,border:Border.all(color:AppColors.cardBorder)),child:Icon(icon,size:18,color:tap==null?AppColors.lightGrey:AppColors.navy))));
  Widget _loading()=>const Center(child:CircularProgressIndicator(color:AppColors.blue));
  Widget _error()=>Center(child:Padding(padding:const EdgeInsets.all(28),child:Column(mainAxisSize:MainAxisSize.min,children:[const Icon(Icons.error_outline_rounded,color:AppColors.red,size:42),const SizedBox(height:12),Text(_controller.errorMessage??'Unable to load contract.',textAlign:TextAlign.center,style:const TextStyle(color:AppColors.grey,fontSize:11.5)),const SizedBox(height:14),FilledButton(onPressed:_load,child:const Text('Retry'))])));
  void _snack(String message,{bool error=false}){ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(behavior:SnackBarBehavior.floating,backgroundColor:error?AppColors.red:AppColors.navy,margin:const EdgeInsets.all(16),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(14)),content:Text(message)));}
}

(Color,Color) _visual(String status){switch(status.trim().toLowerCase()){case'accepted':return(AppColors.green,AppColors.greenBg);case'active':return(AppColors.blue,AppColors.blueBg);case'cancelled':case'terminated':case'rejected':return(AppColors.red,AppColors.redBg);default:return(AppColors.orange,AppColors.orangeBg);}}
String _date(DateTime? d){if(d==null)return'—';final x=d.toLocal();return'${x.year}-${x.month.toString().padLeft(2,'0')}-${x.day.toString().padLeft(2,'0')}';}
String _dateTime(DateTime? d){if(d==null)return'—';final x=d.toLocal();return'${_date(x)} ${x.hour.toString().padLeft(2,'0')}:${x.minute.toString().padLeft(2,'0')}';}
