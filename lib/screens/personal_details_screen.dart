import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'fetch_data_screen.dart';

class PersonalDetailsScreen extends StatefulWidget {
  final DocumentSnapshot? editUser;

  const PersonalDetailsScreen({Key? key, this.editUser}) : super(key: key);

  @override
  _PersonalDetailsScreenState createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Controllers
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _subject1Controller = TextEditingController();
  final TextEditingController _subject2Controller = TextEditingController();
  final TextEditingController _subject3Controller = TextEditingController();
  final TextEditingController _pgSubjectController = TextEditingController();

  // Form variables
  String _selectedGender = '';
  String _selectedMaritalStatus = '';
  String _selectedState = '';
  String _educationalQualification = '';
  File? _selectedImage;
  String? _existingPhotoUrl;

  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeAuth();
    _loadUserDataForEdit();
  }

  Future<void> _initializeAuth() async {
    try {
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        // Sign in anonymously if no user is logged in
        await _auth.signInAnonymously();
      }
    } catch (e) {
      // Silent error handling - just continue without showing error
      print('Auth initialization: $e');
    }
  }

  void _loadUserDataForEdit() {
    if (widget.editUser != null) {
      _isEditMode = true;
      final userData = widget.editUser!.data() as Map<String, dynamic>;

      _nameController.text = userData['name'] ?? '';
      _mobileController.text = userData['mobile'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _selectedGender = userData['gender'] ?? '';
      _selectedMaritalStatus = userData['maritalStatus'] ?? '';
      _selectedState = userData['state'] ?? '';
      _educationalQualification = userData['educationalQualification'] ?? '';
      _existingPhotoUrl = userData['photoUrl'];

      if (userData['educationalQualification'] == 'Graduate' && userData['subjects'] != null) {
        _subject1Controller.text = userData['subjects']['subject1'] ?? '';
        _subject2Controller.text = userData['subjects']['subject2'] ?? '';
        _subject3Controller.text = userData['subjects']['subject3'] ?? '';
      } else if (userData['educationalQualification'] == 'Post Graduate') {
        _pgSubjectController.text = userData['subject'] ?? '';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Details' : 'Personal Details'),
        centerTitle: true,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      drawer: _isEditMode ? null : Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.person_add),
              title: Text('Personal Details'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('Fetch Data'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FetchDataScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPhotoSection(),
                SizedBox(height: 24),
                _buildNameField(),
                SizedBox(height: 16),
                _buildMobileField(),
                SizedBox(height: 16),
                _buildEmailField(),
                SizedBox(height: 16),
                _buildGenderField(),
                SizedBox(height: 16),
                _buildMaritalStatusField(),
                SizedBox(height: 16),
                _buildStateField(),
                SizedBox(height: 16),
                _buildEducationalQualificationField(),
                if (_educationalQualification == 'Graduate') ...[
                  SizedBox(height: 16),
                  _buildSubjectFields(),
                ],
                if (_educationalQualification == 'Post Graduate') ...[
                  SizedBox(height: 16),
                  _buildPGSubjectField(),
                ],
                SizedBox(height: 30),
                _buildActionButtons(),
                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSection() {
    return Center(
      child: Column(
        children: [
          Container(
            height: 150,
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(75),
              border: Border.all(color: Colors.grey[300]!, width: 2),
            ),
            child: _selectedImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(75),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
              ),
            )
                : _existingPhotoUrl != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(75),
              child: Image.network(
                _existingPhotoUrl!,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.person,
                    size: 60,
                    color: Colors.grey[400],
                  );
                },
              ),
            )
                : Icon(
              Icons.person,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Only PNG, JPEG files up to 500KB allowed',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      inputFormatters: [
        LengthLimitingTextInputFormatter(25),
      ],
      decoration: InputDecoration(
        labelText: 'Full Name *',
        hintText: 'Enter your full name',
        prefixIcon: Icon(Icons.person),
        helperText: 'Max 25 characters, can include Roman numerals',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Name is required';
        }
        if (value.length > 25) {
          return 'Name cannot exceed 25 characters';
        }
        if (!RegExp(r'^[a-zA-Z]').hasMatch(value)) {
          return 'Name must start with an alphabet';
        }
        if (!RegExp(r'^[a-zA-Z\s\.\-IVXLCDM]+$').hasMatch(value)) {
          return 'Name can only contain letters, spaces, dots, hyphens, and Roman numerals';
        }
        return null;
      },
    );
  }

  Widget _buildMobileField() {
    return TextFormField(
      controller: _mobileController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: 'Mobile Number *',
        hintText: 'Enter 10-digit mobile number',
        prefixIcon: Icon(Icons.phone),
        helperText: 'Must start with 6, 7, 8, or 9',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Mobile number is required';
        }
        if (value.length != 10) {
          return 'Mobile number must be 10 digits';
        }
        int firstDigit = int.parse(value[0]);
        if (firstDigit >= 0 && firstDigit <= 5) {
          return 'Invalid mobile number. Must start with 6, 7, 8, or 9';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: 'Email Address *',
        hintText: 'Enter your email',
        prefixIcon: Icon(Icons.email),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
          return 'Enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildGenderField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender *',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<String>(
                title: Text('Male'),
                value: 'Male',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text('Female'),
                value: 'Female',
                groupValue: _selectedGender,
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMaritalStatusField() {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Marital Status',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Column(
            children: [
              RadioListTile<String>(
                title: Text('Single'),
                value: 'Single',
                groupValue: _selectedMaritalStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedMaritalStatus = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
              RadioListTile<String>(
                title: Text('Married'),
                value: 'Married',
                groupValue: _selectedMaritalStatus,
                onChanged: (value) {
                  setState(() {
                    _selectedMaritalStatus = value!;
                  });
                },
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStateField() {
    return DropdownButtonFormField<String>(
      value: _selectedState.isEmpty ? null : _selectedState,
      decoration: InputDecoration(
        labelText: 'State *',
        prefixIcon: Icon(Icons.location_on),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: [
        'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
        'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand',
        'Karnataka', 'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur',
        'Meghalaya', 'Mizoram', 'Nagaland', 'Odisha', 'Punjab',
        'Rajasthan', 'Sikkim', 'Tamil Nadu', 'Telangana', 'Tripura',
        'Uttar Pradesh', 'Uttarakhand', 'West Bengal', 'Delhi'
      ].map((state) => DropdownMenuItem<String>(
        value: state,
        child: Text(state),
      )).toList(),
      onChanged: (value) {
        setState(() {
          _selectedState = value!;
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'State is required';
        }
        return null;
      },
    );
  }

  Widget _buildEducationalQualificationField() {
    return DropdownButtonFormField<String>(
      value: _educationalQualification.isEmpty ? null : _educationalQualification,
      decoration: InputDecoration(
        labelText: 'Educational Qualification *',
        prefixIcon: Icon(Icons.school),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: ['Graduate', 'Post Graduate'].map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(value),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _educationalQualification = value!;
          _subject1Controller.clear();
          _subject2Controller.clear();
          _subject3Controller.clear();
          _pgSubjectController.clear();
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Educational qualification is required';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectFields() {
    return Column(
      children: [
        TextFormField(
          controller: _subject1Controller,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
          decoration: InputDecoration(
            labelText: 'Subject 1 *',
            prefixIcon: Icon(Icons.book),
            helperText: 'Max 15 characters',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (_educationalQualification == 'Graduate' && (value == null || value.isEmpty)) {
              return 'Subject 1 is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _subject2Controller,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
          decoration: InputDecoration(
            labelText: 'Subject 2 *',
            prefixIcon: Icon(Icons.book),
            helperText: 'Max 15 characters',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (_educationalQualification == 'Graduate' && (value == null || value.isEmpty)) {
              return 'Subject 2 is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _subject3Controller,
          inputFormatters: [LengthLimitingTextInputFormatter(15)],
          decoration: InputDecoration(
            labelText: 'Subject 3 *',
            prefixIcon: Icon(Icons.book),
            helperText: 'Max 15 characters',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          validator: (value) {
            if (_educationalQualification == 'Graduate' && (value == null || value.isEmpty)) {
              return 'Subject 3 is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPGSubjectField() {
    return TextFormField(
      controller: _pgSubjectController,
      inputFormatters: [LengthLimitingTextInputFormatter(15)],
      decoration: InputDecoration(
        labelText: 'Subject *',
        prefixIcon: Icon(Icons.book),
        helperText: 'Max 15 characters',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (_educationalQualification == 'Post Graduate' && (value == null || value.isEmpty)) {
          return 'Subject is required';
        }
        return null;
      },
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _clearForm,
            child: Text('Cancel'),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey[400]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitForm,
            child: _isLoading
                ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
                : Text(_isEditMode ? 'Update' : 'Submit'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        final File imageFile = File(image.path);
        final int fileSize = await imageFile.length();

        if (fileSize > 500 * 1024) {
          _showSnackBar('Image size should be less than 500 KB', isError: true);
          return;
        }

        String extension = image.path.split('.').last.toLowerCase();
        if (!['png', 'jpg', 'jpeg'].contains(extension)) {
          _showSnackBar('Only PNG and JPEG files are allowed', isError: true);
          return;
        }

        setState(() {
          _selectedImage = imageFile;
        });
      }
    } catch (e) {
      _showSnackBar('Error picking image', isError: true);
    }
  }

  void _clearForm() {
    if (_isEditMode) {
      Navigator.pop(context);
      return;
    }

    _formKey.currentState?.reset();
    setState(() {
      _mobileController.clear();
      _nameController.clear();
      _emailController.clear();
      _subject1Controller.clear();
      _subject2Controller.clear();
      _subject3Controller.clear();
      _pgSubjectController.clear();
      _selectedGender = '';
      _selectedMaritalStatus = '';
      _selectedState = '';
      _educationalQualification = '';
      _selectedImage = null;
    });
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedGender.isEmpty) {
      _showSnackBar('Please select gender', isError: true);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Ensure user is authenticated
      User? currentUser = _auth.currentUser;
      if (currentUser == null) {
        await _auth.signInAnonymously();
        currentUser = _auth.currentUser;
      }

      String? photoUrl = _existingPhotoUrl;

      // Upload photo if new image is selected
      if (_selectedImage != null) {
        try {
          final String fileName = 'user_${currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
          final Reference storageRef = FirebaseStorage.instance
              .ref()
              .child('user_photos')
              .child('$fileName.jpg');

          final SettableMetadata metadata = SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': currentUser.uid,
              'uploadTime': DateTime.now().toIso8601String(),
            },
          );

          final UploadTask uploadTask = storageRef.putFile(_selectedImage!, metadata);
          final TaskSnapshot snapshot = await uploadTask;
          photoUrl = await snapshot.ref.getDownloadURL();
        } catch (storageError) {
          _showSnackBar('Error uploading photo', isError: true);
          setState(() {
            _isLoading = false;
          });
          return;
        }
      }

      Map<String, dynamic> userData = {
        'userId': currentUser!.uid,
        'mobile': _mobileController.text.trim(),
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'gender': _selectedGender,
        'maritalStatus': _selectedMaritalStatus.isNotEmpty ? _selectedMaritalStatus : null,
        'state': _selectedState,
        'educationalQualification': _educationalQualification,
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': DateTime.now().toIso8601String(),
      };

      if (photoUrl != null) {
        userData['photoUrl'] = photoUrl;
      }

      if (_educationalQualification == 'Graduate') {
        userData['subjects'] = {
          'subject1': _subject1Controller.text.trim(),
          'subject2': _subject2Controller.text.trim(),
          'subject3': _subject3Controller.text.trim(),
        };
      } else if (_educationalQualification == 'Post Graduate') {
        userData['subject'] = _pgSubjectController.text.trim();
      }

      if (_isEditMode) {
        userData['updatedAt'] = DateTime.now().toIso8601String();
        await _firestore.collection('users').doc(widget.editUser!.id).update(userData);
        _showSnackBar('Data updated successfully!');
        Navigator.pop(context, true); // Return true to indicate update
      } else {
        await _firestore.collection('users').add(userData);
        _showSnackBar('Data saved successfully!');
        _clearForm();

        // Navigate to FetchDataScr
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FetchDataScreen(),
          ),
        );
      }

    } catch (e) {
      _showSnackBar('Error saving data', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _subject1Controller.dispose();
    _subject2Controller.dispose();
    _subject3Controller.dispose();
    _pgSubjectController.dispose();
    super.dispose();
  }
}