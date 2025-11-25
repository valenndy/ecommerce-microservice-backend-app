from locust import HttpUser, task, between
import random

class EcommerceUser(HttpUser):
    wait_time = between(1, 3)
    
    def on_start(self):
        """Called when a client is spawned"""
        self.products = list(range(1, 21))  # Product IDs 1-20
        self.users = list(range(1, 11))      # User IDs 1-10
        self.orders = []
    
    @task(3)
    def browse_products(self):
        """Simulate browsing products - heaviest task"""
        product_id = random.choice(self.products)
        self.client.get(f"/app/api/products/{product_id}", 
                       name="/app/api/products/[id]")
    
    @task(2)
    def list_products(self):
        """List all products"""
        self.client.get("/app/api/products", name="/app/api/products")
    
    @task(1)
    def get_user_profile(self):
        """Get user profile"""
        user_id = random.choice(self.users)
        self.client.get(f"/app/api/users/{user_id}",
                       name="/app/api/users/[id]")
    
    @task(2)
    def add_to_favorites(self):
        """Add product to favorites"""
        product_id = random.choice(self.products)
        user_id = random.choice(self.users)
        self.client.post(
            f"/app/api/users/{user_id}/favorites",
            json={"productId": product_id},
            name="/app/api/users/[id]/favorites"
        )
    
    @task(1)
    def create_order(self):
        """Create a new order"""
        user_id = random.choice(self.users)
        product_id = random.choice(self.products)
        order_data = {
            "customerId": user_id,
            "items": [
                {
                    "productId": product_id,
                    "quantity": random.randint(1, 5)
                }
            ],
            "shippingAddress": "123 Main Street"
        }
        response = self.client.post(
            "/app/api/orders",
            json=order_data,
            name="/app/api/orders"
        )
        if response.status_code == 200 or response.status_code == 201:
            self.orders.append(response.json()['id'])
    
    @task(1)
    def get_order(self):
        """Get order details"""
        if self.orders:
            order_id = random.choice(self.orders)
            self.client.get(f"/app/api/orders/{order_id}",
                           name="/app/api/orders/[id]")
    
    @task(1)
    def process_payment(self):
        """Process payment"""
        order_id = random.randint(1, 100)
        payment_data = {
            "orderId": order_id,
            "amount": round(random.uniform(10, 1000), 2),
            "paymentMethod": random.choice(["CREDIT_CARD", "DEBIT_CARD", "PAYPAL"])
        }
        self.client.post(
            "/app/api/payments",
            json=payment_data,
            name="/app/api/payments"
        )
    
    @task(1)
    def check_health(self):
        """Check API Gateway health"""
        self.client.get("/app/actuator/health", name="/actuator/health")


class AdminUser(HttpUser):
    """Simulates admin users with different behavior patterns"""
    wait_time = between(2, 5)
    
    @task
    def view_metrics(self):
        """Admin views metrics"""
        self.client.get("/app/actuator/metrics", name="/actuator/metrics")
    
    @task
    def view_prometheus(self):
        """Admin views Prometheus metrics"""
        self.client.get("/app/actuator/prometheus", name="/actuator/prometheus")
