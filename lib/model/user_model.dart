class UserModel{
  String? name;
  String? id;
  String? phone;
  String? childEmail;
  String? parentEmail;
  String? type;

  UserModel({this.name,this.phone,this.childEmail,this.parentEmail,this.id,this.type});

  Map<String, dynamic> toJson() => {
    'name':name,
    'id':id,
    'phone':phone,
    'childEmail':childEmail,
    'parentEmail':parentEmail,
    'type':type,
  };
}