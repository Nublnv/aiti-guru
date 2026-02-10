
class AppError(Exception):
    pass

class OrderNotFoundError(AppError):
    pass

class ItemNotFoundError(AppError):
    pass

class CategoryNotFoundError(AppError):
    pass

class CustomerNotFoundError(AppError):
    pass

class NotEnoughQuantityError(AppError):
    pass