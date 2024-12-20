import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For formatting the selected date
import 'package:hediaty_final/Models/Events.dart';

class EventFormPage extends StatefulWidget {
  final event? ev;
  final int userId;

  const EventFormPage({this.ev, required this.userId});

  @override
  State<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends State<EventFormPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _dateController;
  late TextEditingController _locationController;
  late TextEditingController _descriptionController;

  late AnimationController _animationController;
  late Animation<double> _fadeInAnimation;

  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();

    // Initialize text controllers
    _nameController =
        TextEditingController(text: widget.ev?.name ?? '');
    _locationController =
        TextEditingController(text: widget.ev?.location ?? '');
    _descriptionController =
        TextEditingController(text: widget.ev?.description ?? '');

    if (widget.ev?.date != null) {
      _selectedDate = DateTime.tryParse(widget.ev!.date);
      _dateController = TextEditingController(
          text: _selectedDate != null
              ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
              : '');
    } else {
      _dateController = TextEditingController();
    }

    // Initialize animation controller
    _animationController =
        AnimationController(vsync: this, duration: Duration(milliseconds: 800));
    _fadeInAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    // Start the animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dateController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    DateTime firstDate = DateTime(2000);
    DateTime lastDate = DateTime(2100);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _dateController.text = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      });
    }
  }

  Future<void> saveEvent() async {
    if (_formKey.currentState!.validate()) {
      final ev = widget.ev ??
          event(
              _nameController.text,
              _dateController.text,
              _locationController.text,
              _descriptionController.text,
              widget.userId);

      if (widget.ev == null) {
        await ev.insertevent(_nameController.text, _dateController.text,
            _locationController.text, _descriptionController.text, widget.userId);
      } else {
        await ev.database.updatedata(
          "UPDATE 'Events' SET name = '${_nameController.text}', date = '${_dateController.text}', location = '${_locationController.text}', description = '${_descriptionController.text}' WHERE id = ${widget.ev!.id}",
        );
      }
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.ev == null ? 'Add Event' : 'Edit Event'),
      ),
      body: FadeTransition(
        opacity: _fadeInAnimation,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      widget.ev == null ? 'Create a New Event' : 'Edit Your Event',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Event Name',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Name is required' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _dateController,
                    label: 'Date',
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    suffixIcon: Icon(Icons.calendar_today, color: Colors.blue),
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Date is required' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location',
                    validator: (value) =>
                    value == null || value.isEmpty ? 'Location is required' : null,
                  ),
                  SizedBox(height: 16),
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                  ),
                  SizedBox(height: 30),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      onPressed: saveEvent,
                      child: Text(
                        'Save',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: suffixIcon,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue),
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.blue, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        fillColor: Colors.blue.shade50,
        filled: true,
      ),
      validator: validator,
    );
  }
}
