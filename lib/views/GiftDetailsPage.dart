import 'package:flutter/material.dart';
import 'package:hediaty_final/Models/Gifts.dart';

class GiftDetailsPage extends StatefulWidget {
  final Gift gift;
  final int user_id;

  GiftDetailsPage({required this.gift, required this.user_id});

  @override
  _GiftDetailsPageState createState() => _GiftDetailsPageState();
}

class _GiftDetailsPageState extends State<GiftDetailsPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _categoryController;
  late TextEditingController _priceController;
  late String _status;
  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;
  bool _isPledged = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.gift.name);
    _descriptionController = TextEditingController(text: widget.gift.description);
    _categoryController = TextEditingController(text: widget.gift.category);
    _priceController = TextEditingController(text: widget.gift.price.toString());
    _status = widget.gift.status;
    _isPledged = widget.gift.status == 'pledged';

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );

    _fadeInAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _priceController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _saveGift() async {
    if (_isPledged) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pledged gifts cannot be updated.')),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    widget.gift.name = _nameController.text;
    widget.gift.description = _descriptionController.text;
    widget.gift.category = _categoryController.text;
    widget.gift.price = double.tryParse(_priceController.text) ?? 0.0;
    widget.gift.status = _status;

    if (_status == 'pledged') {
      await widget.gift.pledgeGift(widget.gift.id, widget.user_id);
      widget.gift.userId = widget.user_id;
      _isPledged = true;
    }

    if (widget.gift.id == 0) {
      await widget.gift.insertGift();
    } else {
      await widget.gift.updateGift();
    }

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isPledged ? 'Gift Details (Pledged)' : 'Gift Details',style: TextStyle(color: Colors.white),),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isPledged)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This gift has been pledged and cannot be edited.',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                _buildAnimatedField(
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Name'),
                    enabled: !_isPledged,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a name' : null,
                  ),
                ),
                _buildAnimatedField(
                  TextFormField(
                    controller: _descriptionController,
                    decoration: _inputDecoration('Description'),
                    enabled: !_isPledged,
                    validator: (value) => value == null || value.isEmpty
                        ? 'Please enter a description'
                        : null,
                  ),
                ),
                _buildAnimatedField(
                  TextFormField(
                    controller: _categoryController,
                    decoration: _inputDecoration('Category'),
                    enabled: !_isPledged,
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Please enter a category' : null,
                  ),
                ),
                _buildAnimatedField(
                  TextFormField(
                    controller: _priceController,
                    decoration: _inputDecoration('Price'),
                    keyboardType: TextInputType.number,
                    enabled: !_isPledged,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter a price';
                      final price = double.tryParse(value);
                      if (price == null || price <= 0) return 'Please enter a valid price';
                      return null;
                    },
                  ),
                ),
                _buildAnimatedField(
                  DropdownButtonFormField<String>(
                    value: _status,
                    decoration: _inputDecoration('Status'),
                    items: [
                      DropdownMenuItem(value: 'available', child: Text('Available')),
                      DropdownMenuItem(value: 'pledged', child: Text('Pledged')),
                    ],
                    onChanged: _isPledged
                        ? null
                        : (value) {
                      setState(() {
                        _status = value ?? 'available';
                      });
                    },
                  ),
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.blue,
                    ),
                    onPressed: _saveGift,
                    child: Text(
                      'Save',
                      style: TextStyle(fontSize: 18,color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label, // Replace with the appropriate label
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue), // Border when not focused
        borderRadius: BorderRadius.circular(8),    // Rounded corners
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blue, width: 2), // Border when focused
        borderRadius: BorderRadius.circular(8),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red), // Border when there's an error
        borderRadius: BorderRadius.circular(8),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.red, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      fillColor: Colors.white60, // Light blue background for input
      filled: true,                   // Enable background fill
    );

  }

  Widget _buildAnimatedField(Widget field) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        child: field,
      ),
    );
  }
}
