db.products.insertMany([
    { 'name': 'Server', 'category': 'Hardware', 'price': 1000, 'amount': 15},
    { 'name': 'PC', 'category': 'Hardware', 'price': 250, 'amount': 200},
    { 'name': 'Windows', 'category': 'Software', 'price': 25, 'amount': 550},
    { 'name': 'Office', 'category': 'Software', 'price': 15, 'amount': 550}
  ])
  
print() 
print('1. Вставили 4 документа:')
db.products.find()

print()  
print('2. Посчитали остаточную стоимость:')
db.products.aggregate({
    $group: {
      _id: 'resid_value',
      level: { $sum: { $multiply: ['$price', '$amount']} }
    }
  })

print()
print('3. Уменьшили кол-во товара на 1:')
db.products.updateMany( {}, { $inc: {'amount': -1} }
  )
  
db.products.find()

print()
print('4. Вывели 2 самых дорогих товара:')
db.products.aggregate(
    { $sort: {'price': -1}},
    { $limit: 2}
  )