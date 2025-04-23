import pygame
import random
import math
import queue
import pandas as pd
from datetime import datetime
import time

# ---------------- Global Configuration ----------------

SIMULATION_SPEED = 4.0  # Adjust simulation speed here
update_log = []  # Global log for simulation messages

# Set to store reservations that will have a longer wait time (4-5 minutes)
delayed_reservations = set()
# Counter to limit the number of delayed reservations
delayed_count = 0
# Maximum number of delayed reservations per flight
MAX_DELAYED_RESERVATIONS = 2

def add_update_message(message, color):
    update_log.append((message, color, pygame.time.get_ticks()))
    # Debug print
    print(f"[LOG] {message}")

def load_data():
    """Loads luggage data from CSV and filters for SLHS-handled bags."""
    file_path = "data-large.csv"
    df = pd.read_csv(file_path)
    df['Handled_by_SLHS'] = df['Handled_by_SLHS'].astype(str).str.lower()
    filtered_df = df[df['Handled_by_SLHS'] == 'true']
    return filtered_df

def get_flights_data(data):
    """Organizes luggage data into a dictionary grouped by flight number."""
    flights = data['Flight_Number'].unique()
    flights_data = {}
    for flight in flights:
        flights_data[flight] = data[data['Flight_Number'] == flight]
    return flights_data

def expected_bags_for_reservation(reservation, fallback):
    """
    Returns the expected bag count extracted from the reservation id.
    For instance, if the id ends with "04", returns 4.
    Otherwise, uses the fallback value.
    """
    if reservation[-2:].isdigit():
        return int(reservation[-2:])
    return fallback

# ---------------- Definitions for Conveyor Belt and Key Points ----------------

conveyor_belts = [
    [(1200, 600), (100, 600)],
    [(100, 550), (800, 550)],
    [(200, 500), (800, 500)],
    [(200, 450), (700, 450)],
    [(300, 400), (700, 400)],
    [(300, 350), (600, 350)],
    [(100, 250), (900, 250)],
    [(100, 600), (100, 200)],
    [(200, 500), (200, 200)],
    [(300, 400), (300, 200)],
    [(600, 350), (600, 200)],
    [(700, 450), (700, 200)],
    [(800, 550), (800, 200)],
    [(900, 600), (900, 250)],
    [(580, 200), (600, 250)],
    [(620, 200), (600, 250)],
    [(320, 200), (300, 250)],
    [(280, 200), (300, 250)],
    [(680, 200), (700, 250)],
    [(720, 200), (700, 250)],
    [(180, 200), (200, 250)],
    [(220, 200), (200, 250)],
    [(780, 200), (800, 250)],
    [(820, 200), (800, 250)],
    [(80, 200), (100, 250)],
    [(120, 200), (100, 250)],
]

points = [
    (100, 250), (100, 550), (100, 600),
    (200, 250), (200, 450), (200, 500),
    (300, 250), (300, 350), (300, 400),
    (600, 250), (600, 350), (700, 250),
    (700, 400), (700, 450), (800, 250),
    (800, 500), (800, 550), (900, 250),
    (900, 600)
]

gates_entry_positions = [
    (600, 250),  # Gate 7
    (300, 250),  # Gate 6
    (700, 250),  # Gate 5
    (200, 250),  # Gate 4
    (800, 250),  # Gate 3
    (100, 250),  # Gate 2
]

pickup_gates_positions = [
    (600, 200),  # Gate 7 - 7B
    (580, 200),  # Gate 7 - 7A
    (620, 200),  # Gate 7 - 7C
    (300, 200),  # Gate 6 - 6B
    (320, 200),  # Gate 6 - 6A
    (280, 200),  # Gate 6 - 6C
    (700, 200),  # Gate 5 - 5B
    (680, 200),  # Gate 5 - 5A
    (720, 200),  # Gate 5 - 5C
    (200, 200),  # Gate 4 - 4B
    (180, 200),  # Gate 4 - 4A
    (220, 200),  # Gate 4 - 4C
    (800, 200),  # Gate 3 - 3B
    (780, 200),  # Gate 3 - 3A
    (820, 200),  # Gate 3 - 3C
    (100, 200),  # Gate 2 - 2B
    (80, 200),   # Gate 2 - 2A
    (120, 200),  # Gate 2 - 2C
]

# ---------------- Path and Reservation Color Generation ----------------

class Path:
    def __init__(self, name, points):
        self.name = name
        self.points = points

paths = {
    7: Path("F", [(900, 600), (100, 600), (100, 550), (100, 250)]),
    6: Path("E", [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (800, 250)]),
    5: Path("D", [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500), (200, 450), (200, 250)]),
    4: Path("C", [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500), (200, 450), (700, 450),
                   (700, 400), (700, 250)]),
    3: Path("B", [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500), (200, 450), (700, 450),
                   (700, 400), (300, 400), (300, 350), (300, 250)]),
    2: Path("A", [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500), (200, 450), (700, 450),
                   (700, 400), (300, 400), (300, 350), (600, 350), (600, 250)])
}

paths_2 = {
    cluster: Path(str(cluster), points)
    for cluster, points in {
        7: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)],
        6: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)],
        5: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)],
        4: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)],
        3: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)],
        2: [(900, 600), (100, 600), (100, 550), (800, 550), (800, 500), (200, 500),
            (200, 450), (700, 450), (700, 400), (300, 400), (300, 350), (600, 350),
            (600, 250), (900, 250), (900, 600)]
    }.items()
}

def generate_color_from_id(reservation_id):
    numbers = ''.join(filter(str.isdigit, reservation_id))
    hash_value = hash(numbers) if numbers else hash(reservation_id)
    r = (hash_value % 200) + 30
    g = ((hash_value // 200) % 200) + 30
    b = ((hash_value // 40000) % 200) + 30
    return (r, g, b)

reservation_colors = {}
claim_stats = {}

# ---------------- Bag Class ----------------

class Bag:
    def __init__(self, bag_id, reservation_id, flight_number, num_bags):
        self.ready = False
        self.path = []
        self.bag_id = bag_id
        self.reservation = reservation_id.lower()
        self.flight_number = flight_number
        self.num_bags_in_res = num_bags  # total number of bags in this reservation
        self.position = (1200, 600)
        self.assigned_to_gate = False
        self.gate = None
        self.speed = 2 * SIMULATION_SPEED
        self.target = None
        self.start_time = None
        self.end_time = None
        self.travel_time = None
        self.claimed = False
        if self.reservation not in reservation_colors:
            reservation_colors[self.reservation] = generate_color_from_id(self.reservation)
        self.color = reservation_colors[self.reservation]
        self.last_reassign_attempt = 0

    def set_ready(self):
        self.ready = True
        self.start_time = pygame.time.get_ticks()

    def set_path(self, path):
        self.path = path.points[:] if isinstance(path, Path) else path[:]
        if self.path:
            self.target = self.path.pop(0)

    def set_gate(self, pickup_gate):
        self.gate = pickup_gate
        # Debug print
        print(f"[DEBUG] Bag {self.bag_id} with reservation {self.reservation} assigned to gate {pickup_gate.display_name}")

    def append_path(self, path):
        if isinstance(path, Path):
            self.path.extend(path.points)
        elif isinstance(path, list):
            self.path.extend(path)
        elif isinstance(path, tuple):
            self.path.append(path)
        if not self.target and self.path:
            self.target = self.path.pop(0)

    def has_reached_last_point(self):
        if not self.path:
            return True
        last_x, last_y = self.path[-1]
        return abs(self.position[0] - last_x) < 5 and abs(self.position[1] - last_y) < 5

    def has_reached_gate(self, threshold=8):
        if self.gate is None:
            return False
        gx, gy = self.gate.position
        bx, by = self.position
        return math.hypot(gx - bx, gy - by) < threshold

    def move(self):
        if self.target:
            x, y = self.position
            tx, ty = self.target
            dx = tx - x
            dy = ty - y
            distance = math.hypot(dx, dy)
            if distance <= self.speed or distance < 0.5:
                self.position = self.target
                if self.path:
                    self.target = self.path.pop(0)
                else:
                    self.target = None
                    if not self.assigned_to_gate:
                        # Try to assign to a gate
                        gate_assigned = False
                        
                        # Get the expected bags from the reservation ID
                        expected_bags = expected_bags_for_reservation(self.reservation, self.num_bags_in_res)
                        
                        # Be more lenient in the move method since we can't check remaining bags
                        # Assign to a gate regardless of expected bags count
                        for gate in gate_entries:
                            idx = gate.search(self)
                            if idx != -1:
                                self.set_path(paths[gate.name])
                                gate.gates[idx].set_reservation(self.reservation, expected_bags)
                                self.append_path(gate.gates[idx].position)
                                self.set_gate(gate.gates[idx])
                                self.assigned_to_gate = True
                                gate_assigned = True
                                break
                        if not gate_assigned:
                            self.set_path(paths_2[terminal_priority[0]])
            else:
                self.position = (x + (dx / distance) * self.speed, y + (dy / distance) * self.speed)

    def set_claimed(self):
        if not self.claimed:
            self.claimed = True
            self.end_time = pygame.time.get_ticks()
            self.travel_time = (self.end_time - self.start_time) / 1000.0
            if self.reservation not in claim_stats:
                claim_stats[self.reservation] = {"time": self.travel_time, "bags": 1, "flight": self.flight_number}
            else:
                claim_stats[self.reservation]["bags"] += 1

# ---------------- Gate and PickupGate Classes ----------------

gate_names = {7: "2", 6: "3", 5: "4", 4: "5", 3: "6", 2: "7"}
sub_gate_labels = ["A", "B", "C"]
terminal_priority = [7, 6, 5, 4, 3, 2]

class Gate:
    def __init__(self, name, gates, position):
        self.name = name
        self.display_name = gate_names.get(name, str(name))
        self.gates = gates
        self.position = position
        self.reservation_bags = {}
        self.claim_times = {}

    def max_loading(self):
        for pickup in self.gates:
            pickup.set_max()

    def search(self, bag):
        # First try to assign to a gate with the same reservation that is not full.
        for i, pickup in enumerate(self.gates):
            if pickup.reservation == bag.reservation and not pickup.full:
                return i
        # Otherwise, return the first unreserved gate.
        for i, pickup in enumerate(self.gates):
            if pickup.reservation is None:
                return i
        return -1

    def update_claim_status(self, current_time):
        for reservation, claim_time in list(self.claim_times.items()):
            # Check if this is a delayed reservation
            wait_time = 300000 if reservation in delayed_reservations else 20000  # 5 minutes or 20 seconds
            
            if current_time - claim_time >= wait_time:
                for pickup in self.gates:
                    if pickup.reservation == reservation:
                        for bag in pickup.bags:
                            bag.set_claimed()
                        sub_index = self.gates.index(pickup)
                        sub_label = sub_gate_labels[sub_index]
                        travel_time = pickup.bags[0].travel_time if pickup.bags else 0
                        
                        # Debug print for delayed reservations
                        if reservation in delayed_reservations:
                            msg = f"Delayed reservation {reservation} claimed from Gate {gate_names.get(self.name, self.name)}{sub_label} after 5 minutes"
                            print(f"[DEBUG] {msg}")
                        else:
                            msg = f"Reservation {reservation} claimed from Gate {gate_names.get(self.name, self.name)}{sub_label} in {format_time(travel_time)}"
                        
                        add_update_message(msg, reservation_colors.get(reservation, (0, 0, 0)))
                        pickup.clear_luggage()
                        
                        # Remove from delayed reservations if it was there
                        if reservation in delayed_reservations:
                            delayed_reservations.remove(reservation)
                            
                del self.claim_times[reservation]

    def check_complete_reservations(self):
        current_time = pygame.time.get_ticks()
        global delayed_count
        
        # Check for each pickup gate
        for pickup in self.gates:
            # If the gate has a reservation, has at least one bag, and isn't already in claim timer
            if pickup.reservation and pickup.load > 0 and pickup.reservation not in self.claim_times:
                # Only start the claim timer if we've reached the expected number of bags
                # This ensures gates wait for the correct number of bags based on the reservation ID
                if pickup.load >= pickup.expected_bags:
                    self.claim_times[pickup.reservation] = current_time
                    
                    # Decide if this reservation should be delayed (only for the first few reservations)
                    if delayed_count < MAX_DELAYED_RESERVATIONS and random.random() < 0.2:  # 20% chance
                        delayed_reservations.add(pickup.reservation)
                        delayed_count += 1
                        wait_time = "5 minutes"
                        print(f"[DEBUG] Reservation {pickup.reservation} will be delayed for {wait_time}")
                    else:
                        wait_time = "20 seconds"
                    
                    msg = (f"Starting {wait_time} claim timer for reservation {pickup.reservation} "
                           f"at Gate {gate_names.get(self.name, self.name)}{pickup.name}")
                    add_update_message(msg, reservation_colors.get(pickup.reservation, (0, 0, 0)))

class PickupGate:
    def __init__(self, name, position, parent_gate):
        self.name = name
        self.position = position
        self.parent_gate = parent_gate
        self.display_name = f"{gate_names[parent_gate]}{name}"
        self.reservation = None
        self.load = 0
        self.bags = []
        self.full = False
        self.status = "Available"
        self.pending_start_time = None
        self.expected_bags = 0

    def set_reservation(self, reservation, expected=None):
        if self.reservation is None:
            self.reservation = reservation.lower()
            self.status = "Reserved"
            if expected is None:
                expected = expected_bags_for_reservation(reservation, 1)
            self.expected_bags = expected
            # Debug print
            print(f"[DEBUG] Gate {self.display_name} reserved for reservation {reservation} (expecting {expected} bags)")
            return True
        return False

    def add_luggage(self, bag):
        current_time = pygame.time.get_ticks()
        # Only add this bag if it hasn't already been added.
        if bag.reservation == self.reservation and not self.full:
            if bag not in self.bags:
                self.bags.append(bag)
                self.load += 1
                # Update the pending_start_time whenever a new bag is added
                self.pending_start_time = current_time
                # Debug print
                print(f"[DEBUG] Bag {bag.bag_id} added to gate {self.display_name} ({self.load}/{self.expected_bags})")
            # When the total number of bags equals the expected count, mark the gate as full.
            if self.load >= self.expected_bags:
                self.full = True
                print(f"[DEBUG] Gate {self.display_name} is now full with {self.load} bags")

    def set_max(self):
        pass  # Not used in this version.

    def clear_luggage(self):
        # Debug print
        if self.reservation:
            print(f"[DEBUG] Gate {self.display_name} cleared of reservation {self.reservation}")
        
        self.reservation = None
        self.load = 0
        self.bags = []
        self.full = False
        self.status = "Available"
        self.pending_start_time = None
        self.expected_bags = 0

# ---------------- Initialize Gate Entries ----------------

gate_entries = [
    Gate(7, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[16], 7),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[15], 7),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[17], 7)
    ], gates_entry_positions[5]),
    Gate(6, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[13], 6),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[12], 6),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[14], 6)
    ], gates_entry_positions[4]),
    Gate(5, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[10], 5),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[9], 5),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[11], 5)
    ], gates_entry_positions[3]),
    Gate(4, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[7], 4),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[6], 4),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[8], 4)
    ], gates_entry_positions[2]),
    Gate(3, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[5], 3),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[3], 3),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[4], 3)
    ], gates_entry_positions[1]),
    Gate(2, [
        PickupGate(sub_gate_labels[0], pickup_gates_positions[1], 2),
        PickupGate(sub_gate_labels[1], pickup_gates_positions[0], 2),
        PickupGate(sub_gate_labels[2], pickup_gates_positions[2], 2)
    ], gates_entry_positions[0]),
]

for gate in gate_entries:
    gate.max_loading()

def format_time(seconds):
    minutes = int(seconds // 60)
    sec = int(seconds % 60)
    return f"{minutes:02d}:{sec:02d}"

# ---------------- Utility Functions for Drawing ----------------

def draw_log_box(screen, font):
    box_x, box_y, box_w, box_h = 920, 50, 450, 450
    bg_color = (250, 250, 250)
    BLACK = (0, 0, 0)
    GRAY = (80, 80, 80)
    pygame.draw.rect(screen, bg_color, (box_x, box_y, box_w, box_h))
    pygame.draw.rect(screen, GRAY, (box_x, box_y, box_w, box_h), 2)
    messages_to_show = update_log[-15:]
    text_y = box_y + 5
    for msg, color, _ in messages_to_show:
        text_surface = font.render(msg, True, BLACK)
        screen.blit(text_surface, (box_x + 20, text_y))
        pygame.draw.circle(screen, color, (box_x + 10, text_y + text_surface.get_height() // 2), 5)
        text_y += text_surface.get_height() + 5

def draw_gate_status_box(screen, medium_font, white_color):
    box_x, box_y, box_w, box_h = 920, 400, 450, 180
    bg_color = (250, 250, 250)
    BLACK = (0, 0, 0)
    GRAY = (80, 80, 80)
    pygame.draw.rect(screen, bg_color, (box_x, box_y, box_w, box_h))
    pygame.draw.rect(screen, GRAY, (box_x, box_y, box_w, box_h), 2)
    gate_status_y = box_y + 10
    gate_status_title = medium_font.render("Gate Status:", True, BLACK)
    screen.blit(gate_status_title, (box_x + 10, gate_status_y))
    gate_status_y += gate_status_title.get_height() + 5
    gates_per_line = 3
    gate_line_count = 0
    gate_col_count = 0
    gate_start_x = box_x + 10
    gate_current_x = gate_start_x
    gate_current_y = gate_status_y
    for gate in gate_entries:
        for pickup in gate.gates:
            if pickup.reservation is not None:
                remaining = pickup.expected_bags - pickup.load
                if remaining < 0: 
                    remaining = 0
                
                # Show if this is a delayed reservation
                if pickup.reservation in delayed_reservations:
                    status_str = f"{pickup.status} (DELAYED)"
                else:
                    status_str = f"{pickup.status} ({remaining})"
            else:
                status_str = pickup.status
            gate_line = f"{pickup.display_name}: {status_str}"
            gate_status_surface = medium_font.render(gate_line, True, BLACK)
            screen.blit(gate_status_surface, (gate_current_x + 10, gate_current_y))
            status_color = reservation_colors.get(pickup.reservation, white_color) if pickup.reservation else white_color
            pygame.draw.circle(screen, status_color, (gate_current_x, gate_current_y + gate_status_surface.get_height() // 2), 5)
            gate_current_x += 10 + gate_status_surface.get_width() + 40
            gate_col_count += 1
            if gate_col_count >= gates_per_line:
                gate_current_y += gate_status_surface.get_height() + 5
                gate_current_x = gate_start_x
                gate_col_count = 0
                gate_line_count += 1
            if gate_line_count >= 6:
                break
        if gate_line_count >= 6:
            break

def show_completion_screen(screen, width, height, title_font, subtitle_font, info_font, small_font, flight_num, flight_time, return_on_key=True):
    completion_screen_time = 5  # seconds
    start_ticks = pygame.time.get_ticks()
    clock = pygame.time.Clock()
    WHITE = (255, 255, 255)
    BLACK = (0, 0, 0)
    BLUE = (65, 105, 225)
    GRAY = (200, 200, 200)
    while (pygame.time.get_ticks() - start_ticks) < completion_screen_time * 1000:
        screen.fill(WHITE)
        title_text = title_font.render("Flight Processing Complete", True, BLACK)
        screen.blit(title_text, (width // 2 - title_text.get_width() // 2, 100))
        flight_text = subtitle_font.render(f"Flight: {flight_num}", True, BLUE)
        screen.blit(flight_text, (width // 2 - flight_text.get_width() // 2, 160))
        stats_text = info_font.render("All bags claimed successfully", True, BLACK)
        screen.blit(stats_text, (width // 2 - stats_text.get_width() // 2, 220))
        time_text = info_font.render(f"Total processing time: {format_time(flight_time)}", True, BLACK)
        screen.blit(time_text, (width // 2 - time_text.get_width() // 2, 260))
        continue_text = small_font.render("Press any key to continue to next flight...", True, GRAY)
        screen.blit(continue_text, (width // 2 - continue_text.get_width() // 2, height - 100))
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return True
            elif event.type == pygame.KEYDOWN and return_on_key:
                return False
        pygame.display.update()
        clock.tick(30)
    return False

def show_waiting_screen(screen, width, height, title_font, subtitle_font, info_font, small_font, next_flight, wait_total=30):
    WHITE = (255, 255, 255)
    BLACK = (0, 0, 0)
    BLUE = (65, 105, 225)
    GRAY = (200, 200, 200)
    clock = pygame.time.Clock()
    wait_start = pygame.time.get_ticks()
    waiting = True
    while waiting:
        current_time = pygame.time.get_ticks()
        elapsed = (current_time - wait_start) / 1000.0
        remaining = wait_total - elapsed
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                return True
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_SPACE:
                    waiting = False
        if remaining <= 0:
            break
        screen.fill(WHITE)
        title_text = title_font.render("Smart Luggage Handling System", True, BLACK)
        screen.blit(title_text, (width // 2 - title_text.get_width() // 2, 20))
        next_text = subtitle_font.render(f"Next Flight: {next_flight}", True, BLUE)
        screen.blit(next_text, (width // 2 - next_text.get_width() // 2, height // 2 - 60))
        wait_msg = subtitle_font.render("Waiting between flights:", True, BLACK)
        screen.blit(wait_msg, (width // 2 - wait_msg.get_width() // 2, height // 2 - 20))
        time_remaining = info_font.render(f"Time remaining: {format_time(remaining)}", True, BLACK)
        screen.blit(time_remaining, (width // 2 - time_remaining.get_width() // 2, height // 2 + 20))
        skip_msg = info_font.render("Press SPACE to skip waiting time", True, GRAY)
        screen.blit(skip_msg, (width // 2 - skip_msg.get_width() // 2, height // 2 + 60))
        pygame.display.update()
        clock.tick(10)
    return False

def reset_flight_state():
    global update_log, claim_stats, gate_entries, delayed_reservations, delayed_count
    update_log.clear()
    claim_stats.clear()
    delayed_reservations.clear()
    delayed_count = 0
    
    # Reset all gate entries to ensure they don't carry over reservations
    for gate in gate_entries:
        for pickup in gate.gates:
            pickup.clear_luggage()
        gate.claim_times.clear()
        gate.reservation_bags.clear()

# ---------------- Main Simulation ----------------

def main():
    WHITE = (255, 255, 255)
    BLACK = (0, 0, 0)
    BLUE = (65, 105, 225)
    GRAY = (200, 200, 200)
    try:
        filtered_df = load_data()
        print("Loaded the bags - handled by SLHS")
    except Exception as e:
        print(f"Error loading data: {e}")
        filtered_df = pd.DataFrame()
    flights_data = get_flights_data(filtered_df)
    flight_list = list(flights_data.items())
    print(f"Found {len(flight_list)} flights")
    pygame.init()
    width, height = 1400, 720
    screen = pygame.display.set_mode((width, height))
    pygame.display.set_caption("Smart Luggage Handling System")
    title_font = pygame.font.SysFont('Arial', 28, bold=True)
    subtitle_font = pygame.font.SysFont('Arial', 20)
    info_font = pygame.font.SysFont('Arial', 16)
    medium_font = pygame.font.SysFont('Arial', 14)
    small_font = pygame.font.SysFont('Arial', 12)
    clock = pygame.time.Clock()
    
    # Process flights one by one.
    for flight_idx, (flight_num, flight_data) in enumerate(flight_list):
        print(f"Processing flight {flight_num}")
        # Group rows by Reservation_ID; each row is one bag.
        reservations = flight_data.groupby('Reservation_ID')
        all_bags = []
        for reservation_id, res_data in reservations:
            num_bags = len(res_data)  # Total bags for this reservation.
            for _, row in res_data.iterrows():
                bag = Bag(
                    row['Bag_ID'],
                    row['Reservation_ID'],
                    row['Flight_Number'],
                    num_bags
                )
                all_bags.append(bag)
        random.shuffle(all_bags)
        conveyor_belt = all_bags
        scanned_bags = []
        i = 0
        spawn_interval = int(500 / SIMULATION_SPEED)
        last_spawn_time = pygame.time.get_ticks()
        flight_start_time = pygame.time.get_ticks()
        flight_complete = False
        
        while not flight_complete:
            screen.fill(WHITE)
            # Draw header and flight info.
            title_text = title_font.render("Smart Luggage Handling System", True, BLACK)
            screen.blit(title_text, (width // 2 - title_text.get_width() // 2, 20))
            flight_text = subtitle_font.render(f"Flight: {flight_num}", True, BLUE)
            screen.blit(flight_text, (width // 2 - flight_text.get_width() // 2, 60))
            elapsed_seconds = (pygame.time.get_ticks() - flight_start_time) / 1000.0
            time_text = info_font.render(f"Elapsed Time: {format_time(elapsed_seconds)}", True, BLACK)
            screen.blit(time_text, (20, 20))
            
            # Draw conveyor belts and key points.
            for belt in conveyor_belts:
                pygame.draw.line(screen, BLACK, belt[0], belt[1], 3)
            for point in points:
                pygame.draw.circle(screen, BLACK, point, 5)
            
            # Draw gate entries and pickup gates.
            for gate in gate_entries:
                pygame.draw.rect(screen, BLACK, (gate.position[0] - 5, gate.position[1] - 5, 10, 10))
                for pickup in gate.gates:
                    if pickup.reservation is None:
                        pygame.draw.rect(screen, BLACK, (pickup.position[0] - 5, pickup.position[1] - 5, 10, 10))
                    else:
                        gate_color = reservation_colors.get(pickup.reservation, BLACK)
                        pygame.draw.circle(screen, gate_color, pickup.position, 5)
                    point_label = small_font.render(pickup.display_name, True, BLACK)
                    screen.blit(point_label, (pickup.position[0] - 12, pickup.position[1] - 20))
            
            help_text = small_font.render("Press ESC to exit | SPACE to skip wait time", True, GRAY)
            screen.blit(help_text, (width - 300, height - 20))
            
            draw_log_box(screen, medium_font)
            draw_gate_status_box(screen, medium_font, WHITE)
            
            # Event handling.
            for event in pygame.event.get():
                if event.type == pygame.QUIT:
                    pygame.quit()
                    return
                elif event.type == pygame.KEYDOWN:
                    if event.key == pygame.K_ESCAPE:
                        pygame.quit()
                        return
            
            current_time = pygame.time.get_ticks()
            for gate in gate_entries:
                gate.update_claim_status(current_time)
                gate.check_complete_reservations()
            
            # Spawn new bags.
            if i < len(conveyor_belt) and current_time - last_spawn_time >= spawn_interval:
                bag = conveyor_belt[i]
                scanned_bags.append(bag)
                bag.set_ready()
                bag.spawn_time = current_time
                reservation_id = bag.reservation
                assigned_gate = False
                # First try to assign to a gate that already has this reservation.
                for gate in gate_entries:
                    for pickup in gate.gates:
                        if pickup.reservation == reservation_id:
                            bag.set_path(paths[gate.name])
                            bag.append_path(pickup.position)
                            bag.set_gate(pickup)
                            bag.assigned_to_gate = True
                            assigned_gate = True
                            if reservation_id not in gate.reservation_bags:
                                gate.reservation_bags[reservation_id] = []
                            gate.reservation_bags[reservation_id].append(bag)
                            break
                    if assigned_gate:
                        break
                # Otherwise, assign to a free gate.
                if not assigned_gate:
                    # Count how many bags with this reservation are left to be processed
                    remaining_bags_with_id = 1  # Start with 1 for the current bag
                    for remaining_bag in conveyor_belt[i+1:]:  # Skip the current bag
                        if remaining_bag.reservation == reservation_id:
                            remaining_bags_with_id += 1
                    
                    # Get the expected bags from the reservation ID
                    expected_bags = expected_bags_for_reservation(bag.reservation, bag.num_bags_in_res)
                    
                    # Reserve a gate if:
                    # 1. There are enough bags left to fulfill the expected count, or
                    # 2. This is a single bag reservation, or
                    # 3. We're at the start of the simulation (i < 20) - this ensures gates get reserved at the beginning
                    # Restoring the i < 20 condition to ensure better gate distribution
                    if remaining_bags_with_id >= expected_bags - 1 or expected_bags == 1 or i < 20:
                        for gate in gate_entries:
                            idx = gate.search(bag)
                            if idx != -1:
                                gate.gates[idx].set_reservation(bag.reservation, expected_bags)
                                bag.set_path(paths[gate.name])
                                bag.append_path(gate.gates[idx].position)
                                bag.set_gate(gate.gates[idx])
                                bag.assigned_to_gate = True
                                if reservation_id not in gate.reservation_bags:
                                    gate.reservation_bags[reservation_id] = []
                                gate.reservation_bags[reservation_id].append(bag)
                                break
                    # If not enough bags left, don't reserve a gate
                    else:
                        bag.set_path(paths_2[terminal_priority[0]])
                        print(f"[DEBUG] Not enough bags left for reservation {reservation_id}, not reserving a gate")
                    if not bag.assigned_to_gate:
                        bag.set_path(paths_2[terminal_priority[0]])
                i += 1
                last_spawn_time = current_time
            
            # Move and draw bags.
            still_moving = False
            for bag in scanned_bags:
                if not bag.claimed:
                    if bag.assigned_to_gate and bag.has_reached_gate():
                        for gate in gate_entries:
                            if gate.name == bag.gate.parent_gate:
                                gate.gates[gate.gates.index(bag.gate)].add_luggage(bag)
                                break
                        pygame.draw.circle(screen, bag.color, bag.position, 8)
                    else:
                        bag.move()
                        pygame.draw.circle(screen, bag.color, bag.position, 8)
                        still_moving = True
                else:
                    pygame.draw.rect(screen, BLACK, (bag.position[0] - 5, bag.position[1] - 5, 10, 10))
            
            pygame.display.update()
            clock.tick(60)
            
            # Check for gates with reservations that won't receive enough bags
            if i >= len(conveyor_belt) - 5:  # When we're near the end of the conveyor belt
                # Count remaining bags by reservation
                remaining_bags_by_reservation = {}
                for remaining_bag in conveyor_belt[i:]:
                    if remaining_bag.reservation not in remaining_bags_by_reservation:
                        remaining_bags_by_reservation[remaining_bag.reservation] = 0
                    remaining_bags_by_reservation[remaining_bag.reservation] += 1
                
                # Check each gate for unfulfillable reservations
                for gate in gate_entries:
                    for pickup in gate.gates:
                        if pickup.reservation and pickup.reservation not in gate.claim_times:
                            # If this gate has a reservation but not enough bags left to fulfill it
                            remaining = remaining_bags_by_reservation.get(pickup.reservation, 0)
                            needed = pickup.expected_bags - pickup.load
                            
                            if needed > 0 and remaining < needed:
                                print(f"[DEBUG] Gate {pickup.display_name} has reservation {pickup.reservation} but only {remaining} bags left (needs {needed} more)")
                                
                                # If there are some bags in the gate, start the claim timer
                                if pickup.load > 0:
                                    print(f"[DEBUG] Starting claim timer for partially filled gate {pickup.display_name}")
                                    gate.claim_times[pickup.reservation] = current_time
                                    msg = f"Starting 20s claim timer for reservation {pickup.reservation} (partial: {pickup.load}/{pickup.expected_bags}) at Gate {gate_names.get(gate.name, gate.name)}{pickup.name}"
                                    add_update_message(msg, reservation_colors.get(pickup.reservation, (0, 0, 0)))
                                # We're no longer releasing empty gates to maintain better distribution
                                # This ensures gates stay reserved even if they might not get all expected bags
            
            # Check if flight is complete.
            # Only complete if:
            # 1. All bags have been processed
            # 2. No bags are still moving
            # 3. No active reservations in any gate's claim_times (especially delayed ones)
            
            active_reservations = False
            for gate in gate_entries:
                if gate.claim_times:  # If any gate has active claim timers
                    active_reservations = True
                    break
            
            if i >= len(conveyor_belt) and not flight_complete and not still_moving and not active_reservations:
                flight_complete = True
                print("[DEBUG] Flight complete - all bags processed and all reservations claimed")
            elif i >= len(conveyor_belt) and not still_moving and active_reservations:
                # All bags processed but still waiting for reservations to be claimed
                waiting_for = []
                for gate in gate_entries:
                    for res_id in gate.claim_times:
                        delay_status = "delayed" if res_id in delayed_reservations else "normal"
                        waiting_for.append(f"{res_id} ({delay_status})")
                
                if waiting_for:
                    print(f"[DEBUG] Waiting for reservations to be claimed: {', '.join(waiting_for)}")
        
        flight_time = (pygame.time.get_ticks() - flight_start_time) / 1000.0
        show_completion_screen(screen, width, height, title_font, subtitle_font, info_font, small_font, flight_num, flight_time, return_on_key=False)
        if flight_idx < len(flight_list) - 1:
            next_flight = flight_list[flight_idx + 1][0]
            show_waiting_screen(screen, width, height, title_font, subtitle_font, info_font, small_font, next_flight, wait_total=0)
            reset_flight_state()
    pygame.quit()

if __name__ == "__main__":
    main()
