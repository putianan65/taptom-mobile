import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/database_helper.dart';
import '../../../../core/services/gap_service.dart';
import '../../../../core/utils/error_utils.dart';
import '../../widgets/gap_form_wrapper.dart';

class GapInputsForm extends StatefulWidget {
  final String plotId;
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const GapInputsForm({
    super.key,
    required this.plotId,
    this.existingId,
    this.existingData,
  });

  @override
  State<GapInputsForm> createState() => _GapInputsFormState();
}

class _GapInputsFormState extends State<GapInputsForm>
    with SingleTickerProviderStateMixin {
  final _gapService = GapService();
  late TabController _tabController;
  List<dynamic> _inputs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      if (widget.existingData != null) {
        // Edit mode - typically inputs are fetched as a list for the plot,
        // but if we are editing a single input (not yet supported by UI structure effectively,
        // as this form manages ALL inputs for a plot), we might need to adjust.
        // However, based on the provided code structure, GapInputsForm manages a LIST of inputs.
        // If existingData contains a list of inputs, we use it.
        // But usually existingData passed from summary might be a single record or a summary object.
        // Let's assume for 'inputs' category, the summary passes the LIST of inputs or we just fetch fresh.
        // Looking at GapMainScreen, it passes: inputs.isNotEmpty ? inputs.first : null
        // This suggests existingData might be a SINGLE input record if the intention was to edit one.
        // But GapInputsForm UI shows a list (Tabs for Seeds, Fertilizer, etc.)
        // So actually, for "Inputs", we usually want to load ALL inputs for the plot.
        // If widget.existingData is passed, it might be just to trigger "Edit Mode" visually or
        // if it contains the full list.
        // Let's stick to fetching fresh data to be safe, BUT if we want to support "offline edit"
        // we should check if existingData has the list.

        // For now, to match the pattern of other forms (like GapHarvestForm),
        // we'll prioritize fetching fresh data for 'Inputs' because it's a list management form,
        // unlike HarvestForm which edits a single Harvest event.
        // BUT, to fix the build error and support the "intention" of passing parameters:

        final data = await _gapService.getInputs(widget.plotId);
        if (mounted) {
          setState(() {
            _inputs = data;
            _isLoading = false;
          });
        }
      } else {
        // New/Normal mode
        final data = await _gapService.getInputs(widget.plotId);
        if (mounted) {
          setState(() {
            _inputs = data;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      // Silent failure - inputs list will be empty
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveDraft() async {
    final messenger = ScaffoldMessenger.of(context);
    await DatabaseHelper.instance.saveDraft(
      'inputs_${widget.plotId}',
      jsonEncode({'inputs': _inputs}),
    );
    if (mounted) {
      messenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(PhosphorIconsRegular.cloudCheck, color: Colors.white),
              const SizedBox(width: 8),
              Text('บันทึกร่างเรียบร้อย', style: const TextStyle()),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // GAP-FIX: Store navigator before build to avoid context issues after dispose
    final navigator = Navigator.of(context);

    return GapFormWrapper(
      title: '2. ปัจจัยการผลิต',
      subtitle: 'บันทึกปัจจัยการผลิตที่ใช้',
      headerIcon: PhosphorIconsRegular.flask,
      headerColor: Colors.teal,
      onSave: () => navigator.pop(true),
      onSaveDraft: _saveDraft,
      hasUnsavedChanges: false, // Inputs are saved immediately via dialog
      child: _isLoading
          ? const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const FormInfoCard(
                    message:
                        'บันทึกเมล็ดพันธุ์ ปุ๋ย และสารป้องกันโรคที่ใช้ในแปลง',
                    icon: PhosphorIconsRegular.lightbulb,
                    color: Colors.teal,
                  ),

                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      unselectedLabelStyle: TextStyle(fontSize: 12),
                      indicatorSize: TabBarIndicatorSize.tab,
                      padding: const EdgeInsets.all(4),
                      tabs: const [
                        Tab(text: 'เมล็ด/กิ่งพันธุ์'),
                        Tab(text: 'ปุ๋ย'),
                        Tab(text: 'สารป้องกัน'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTabContent(
                          type: 'SEED',
                          icon: PhosphorIconsRegular.sparkle,
                          color: Colors.green,
                          title: 'เมล็ด/กิ่งพันธุ์',
                          emptyText: 'ยังไม่มีข้อมูลเมล็ด/กิ่งพันธุ์',
                          buttonText: 'เพิ่มเมล็ด/กิ่งพันธุ์',
                          examples: {
                            'name': 'กิ่งพันธุ์หางกระรอก',
                            'source': 'ศูนย์วิจัยพืชสวนพิษณุโลก',
                            'amount': '50 กิ่ง',
                          },
                        ),
                        _buildTabContent(
                          type: 'FERTILIZER',
                          icon: PhosphorIconsRegular.flask,
                          color: Colors.brown,
                          title: 'ปุ๋ยและสารบำรุง',
                          emptyText: 'ยังไม่มีข้อมูลปุ๋ย',
                          buttonText: 'เพิ่มปุ๋ย/สารบำรุง',
                          examples: {
                            'name': 'ปุ๋ยอินทรีย์ 15-15-15',
                            'source': 'ร้านเกษตรท่าเรือ',
                            'amount': '25 กก.',
                          },
                        ),
                        _buildChemicalsTab(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
    );
  }

  Widget _buildTabContent({
    required String type,
    required IconData icon,
    required Color color,
    required String title,
    required String emptyText,
    required String buttonText,
    required Map<String, String> examples,
  }) {
    final items = _inputs.where((i) => i['type'] == type).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                _buildAddButton(
                  color: color,
                  icon: icon,
                  text: buttonText,
                  onTap: () => _showAddInputDialog(type, title, examples),
                ),

                const SizedBox(height: 16),

                if (items.isEmpty)
                  _buildEmptyState(icon, emptyText, color)
                else
                  ...items.map((item) => _buildInputCard(item, color, icon)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildChemicalsTab() {
    final items = _inputs.where((i) => i['type'] == 'PESTICIDE').toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          PhosphorIconsRegular.warning,
                          color: Colors.red,
                          size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'คำเตือน: ต้องหยุดพ่นสารก่อนเก็บเกี่ยว 7-15 วัน',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                _buildAddButton(
                  color: Colors.orange,
                  icon: PhosphorIconsRegular.shieldWarning,
                  text: 'เพิ่มสารป้องกันโรค',
                  onTap: () =>
                      _showAddInputDialog('PESTICIDE', 'สารป้องกันโรค', {
                        'name': 'น้ำมันสะเดา (Neem Oil)',
                        'source': 'สหกรณ์การเกษตร',
                        'amount': '2 ลิตร',
                      }),
                ),

                const SizedBox(height: 16),

                if (items.isEmpty)
                  _buildEmptyState(
                    PhosphorIconsRegular.shieldWarning,
                    'ยังไม่มีข้อมูลสารป้องกันโรค',
                    Colors.orange,
                  )
                else
                  ...items.map(
                    (item) => _buildInputCard(
                      item,
                      Colors.orange,
                      PhosphorIconsRegular.shieldWarning,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAddButton({
    required Color color,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(PhosphorIconsRegular.plus, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.3), size: 48),
          const SizedBox(height: 12),
          Text(text, style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildInputCard(
    Map<String, dynamic> item,
    Color color,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['name'] ?? '-',
                  style: TextStyle(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'แหล่ง: ${item['source'] ?? '-'}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'ปริมาณ: ${item['amount'] ?? '0'} ${item['unit'] ?? ''}',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showAddInputDialog(
    String type,
    String title,
    Map<String, String> examples,
  ) async {
    final nameController = TextEditingController();
    final sourceController = TextEditingController();
    final amountController = TextEditingController();
    final unitController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(dialogContext).viewInsets.bottom + 20,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'เพิ่ม$title',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            _buildDialogField(
              'ชื่อ/ชนิด *',
              nameController,
              'ตัวอย่าง: ${examples['name']}',
            ),
            const SizedBox(height: 12),
            _buildDialogField(
              'แหล่งที่มา *',
              sourceController,
              'ตัวอย่าง: ${examples['source']}',
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDialogField(
                    'ปริมาณ (ตัวเลข) *',
                    amountController,
                    'เช่น 50',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDialogField(
                    'หน่วย *',
                    unitController,
                    'เช่น กก.',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(dialogContext);
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('ยกเลิก', style: const TextStyle()),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'กรุณากรอกชื่อ/ชนิด',
                              style: const TextStyle(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (sourceController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'กรุณากรอกแหล่งที่มา',
                              style: const TextStyle(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final amount = double.tryParse(amountController.text);
                      if (amount == null || amount <= 0) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'กรุณากรอกปริมาณที่ถูกต้อง (จำนวนบวก)',
                              style: const TextStyle(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      if (unitController.text.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              'กรุณากรอกหน่วย',
                              style: const TextStyle(),
                            ),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }

                      final data = {
                        'name': nameController.text,
                        'source': sourceController.text,
                        'amount': amount,
                        'unit': unitController.text,
                      };

                      Navigator.pop(dialogContext, data);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'บันทึก',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (result != null && result['name']?.isNotEmpty == true) {
      if (!mounted) return;
      
      // Store messenger reference before async operations
      final messenger = ScaffoldMessenger.of(context);
      
      try {
        // GAP-FIX: Do NOT send 'date' — backend rejects it (400: property date should not exist)
        await _gapService.addInput(widget.plotId, {
          'type': type,
          ...result,
        });
        await _loadData();

        if (!mounted) return;
        
        messenger.showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(PhosphorIconsFill.checkCircle, color: Colors.white),
                const SizedBox(width: 8),
                Text('เพิ่มข้อมูลสำเร็จ', style: const TextStyle()),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              ErrorUtils.getReadableError(e),
              style: const TextStyle(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildDialogField(
    String label,
    TextEditingController controller,
    String hint, {
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: keyboardType == TextInputType.number ? 10 : 100,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            counterText: '',
          ),
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
