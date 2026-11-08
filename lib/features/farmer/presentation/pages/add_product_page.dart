import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../catalog/data/product_model.dart';
import '../../data/farmer_product_repository.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = FarmerProductRepository.instance;
  bool _guardando = false;

  // Route arguments to determine if we are editing
  Producto? _editingProduct;
  bool _isInit = true;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _priceBoxCtrl = TextEditingController();
  final _stockBoxCtrl = TextEditingController();
  final _unitsBoxCtrl = TextEditingController();

  // State fields
  String? _selectedCategory;
  bool _sellByKilo = true;
  bool _sellByBox = false;
  File? _selectedImage;
  String _existingImageUrl = '';

  final List<String> _categories = [
    'Verduras',
    'Frutas',
    'Hierbas',
    'Tubérculos',
    'Granos y cereales',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Producto) {
        _editingProduct = args;
        _nameCtrl.text = _editingProduct!.nombre;
        _descriptionCtrl.text = _editingProduct!.descripcion;
        _priceCtrl.text = _editingProduct!.precio.toStringAsFixed(2);
        _stockCtrl.text = _editingProduct!.stockDisponible.toStringAsFixed(0);
        _weightCtrl.text = _editingProduct!.pesoUnidadAprox.toString();
        _selectedCategory = categoryToLabel(_editingProduct!.categoria);
        _sellByKilo = _editingProduct!.ventaPorKilo;
        _sellByBox = _editingProduct!.ventaPorCaja;
        _existingImageUrl = _editingProduct!.urlImagen;

        _priceBoxCtrl.text =
            _editingProduct!.precioCaja?.toStringAsFixed(2) ?? '';
        _stockBoxCtrl.text =
            _editingProduct!.stockCaja?.toStringAsFixed(0) ?? '';
        _unitsBoxCtrl.text =
            _editingProduct!.unidadesCajaReferencial?.toStringAsFixed(0) ?? '';
      }
      _isInit = false;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descriptionCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _weightCtrl.dispose();
    _priceBoxCtrl.dispose();
    _stockBoxCtrl.dispose();
    _unitsBoxCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_sellByKilo && !_sellByBox) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un formato de venta.'),
        ),
      );
      return;
    }

    if (_editingProduct == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una imagen para el producto.'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final category = _selectedCategory ?? 'Frutas';
    final name = _nameCtrl.text.trim();
    final description = _descriptionCtrl.text.trim();

    final price = double.tryParse(_priceCtrl.text) ?? 0.0;
    final stock = double.tryParse(_stockCtrl.text) ?? 0.0;
    final weight = double.tryParse(_weightCtrl.text) ?? 0.4;

    final priceBox = double.tryParse(_priceBoxCtrl.text);
    final stockBox = double.tryParse(_stockBoxCtrl.text);
    final unitsBox = double.tryParse(_unitsBoxCtrl.text);

    final datos = {
      'name': name,
      'description': description,
      'category': labelToCategory(category),
      'saleFormats': [
        if (_sellByKilo)
          {
            'saleFormat': 'KILO',
            'price': price,
            'stock': stock,
            'referenceUnitWeightKg': weight,
          },
        if (_sellByBox)
          {
            'saleFormat': 'CAJA',
            'price': priceBox ?? 0.0,
            'stock': stockBox ?? 0.0,
            'unitsPerBox': (unitsBox ?? 0).toInt(),
          },
      ],
    };

    try {
      if (_editingProduct == null) {
        await _repository.createProduct(datos, imageFile: _selectedImage!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" guardado. Sincronización pendiente.'),
            ),
          );
        }
      } else {
        await _repository.updateProduct(
          _editingProduct!.id,
          datos,
          imageFile: _selectedImage,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"$name" actualizado. Sincronizando cambios...'),
            ),
          );
        }
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _editingProduct != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Editar producto' : 'Agregar producto',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
      ),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Upload Widget
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _selectedImage != null
                        ? ClipOval(
                            child: Image.file(
                              _selectedImage!,
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                            ),
                          )
                        : _existingImageUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              _existingImageUrl,
                              fit: BoxFit.cover,
                              width: 140,
                              height: 140,
                            ),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_outlined,
                                color: Colors.black54,
                                size: 28,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Subir imagen *',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Nombre Field
              _buildLabel('Nombre *'),
              TextFormField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: _buildInputDecoration(
                  'Ingresar nombre del producto',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa el nombre del producto'
                    : null,
              ),
              const SizedBox(height: 20),

              _buildLabel('Descripción *'),
              TextFormField(
                controller: _descriptionCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLength: 500,
                maxLines: 4,
                decoration: _buildInputDecoration(
                  'Describe el origen, calidad y características del producto',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Ingresa la descripción del producto'
                    : null,
              ),
              const SizedBox(height: 20),

              // Categoria Field
              _buildLabel('Categoria *'),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                style: const TextStyle(fontSize: 15, color: Colors.black),
                decoration: _buildInputDecoration('Seleccione una categoria'),
                items: _categories.map((cat) {
                  return DropdownMenuItem<String>(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedCategory = val;
                  });
                },
                validator: (value) =>
                    value == null ? 'Selecciona una categoría' : null,
              ),
              const SizedBox(height: 24),

              // Formato de venta title
              _buildLabel('Formato de venta *'),
              const SizedBox(height: 8),

              // 1. Por kilogramo Card
              _buildSaleFormatCard(
                title: 'Por kilogramo',
                isActive: _sellByKilo,
                iconData: Icons.shopping_bag_outlined,
                onChanged: (val) {
                  setState(() {
                    _sellByKilo = val;
                  });
                },
                extraFields: !_sellByKilo
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Color(0xFFECECEC), height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Precio (s/.)*'),
                                    TextFormField(
                                      controller: _priceCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _buildInputDecoration('0.00'),
                                      validator: (value) {
                                        if (!_sellByKilo) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Stock (kg) *'),
                                    TextFormField(
                                      controller: _stockCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration('0'),
                                      validator: (value) {
                                        if (!_sellByKilo) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Peso unitario referencial (kg)*'),
                          TextFormField(
                            controller: _weightCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _buildInputDecoration(
                              'Ej: 0.4 kg por unidad',
                            ),
                            validator: (value) {
                              if (!_sellByKilo) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 16),

              // 2. Por caja Card
              _buildSaleFormatCard(
                title: 'Por caja',
                isActive: _sellByBox,
                iconData: Icons.all_inbox_outlined,
                onChanged: (val) {
                  setState(() {
                    _sellByBox = val;
                  });
                },
                extraFields: !_sellByBox
                    ? null
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(color: Color(0xFFECECEC), height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Precio (s/.)*'),
                                    TextFormField(
                                      controller: _priceBoxCtrl,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: _buildInputDecoration('0.00'),
                                      validator: (value) {
                                        if (!_sellByBox) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel('Stock (cajas) *'),
                                    TextFormField(
                                      controller: _stockBoxCtrl,
                                      keyboardType: TextInputType.number,
                                      decoration: _buildInputDecoration('0'),
                                      validator: (value) {
                                        if (!_sellByBox) return null;
                                        if (value == null ||
                                            value.trim().isEmpty) {
                                          return 'Requerido';
                                        }
                                        if (double.tryParse(value) == null) {
                                          return 'Inválido';
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildLabel('Unidades por caja (referencial)*'),
                          TextFormField(
                            controller: _unitsBoxCtrl,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: _buildInputDecoration(
                              'Ej: 15 unidades por caja',
                            ),
                            validator: (value) {
                              if (!_sellByBox) return null;
                              if (value == null || value.trim().isEmpty) {
                                return 'Requerido';
                              }
                              if (double.tryParse(value) == null) {
                                return 'Inválido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 40),

              // Bottom Actions: Volver and Agregar/Guardar
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(
                            color: Color(0xFFD6D6D6),
                            width: 1.5,
                          ),
                          shape: const StadiumBorder(),
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text(
                          'Volver',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _guardando ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5CA399),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: const StadiumBorder(),
                        ),
                        child: _guardando
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Guardar' : 'Agregar',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF5CA399), width: 1.5),
      ),
      errorStyle: const TextStyle(fontSize: 11, height: 0.8),
    );
  }

  Widget _buildSaleFormatCard({
    required String title,
    required bool isActive,
    required IconData iconData,
    required ValueChanged<bool> onChanged,
    Widget? extraFields,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? const Color(0xFF5CA399).withOpacity(0.5)
              : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xFFE0F2F1)
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: isActive ? const Color(0xFF5CA399) : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isActive ? 'Activo • completa los datos' : 'Inactivo',
                      style: TextStyle(
                        fontSize: 11,
                        color: isActive
                            ? const Color(0xFF5CA399)
                            : Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isActive,
                onChanged: onChanged,
                activeColor: const Color(0xFF5CA399),
                activeTrackColor: const Color(0xFF5CA399).withOpacity(0.2),
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade200,
              ),
            ],
          ),
          if (extraFields != null) extraFields,
        ],
      ),
    );
  }
}
