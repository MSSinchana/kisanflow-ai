import csv
import os
from datetime import datetime

from flask import Flask, jsonify, request

app = Flask(__name__)

HISTORICAL_CSV_PATH = os.path.join(os.path.dirname(__file__), 'data', 'historical_queue.csv')


def load_historical_data():
  rows = []
  if not os.path.exists(HISTORICAL_CSV_PATH):
    return rows

  with open(HISTORICAL_CSV_PATH, newline='', encoding='utf-8') as csvfile:
    reader = csv.DictReader(csvfile)
    for row in reader:
      try:
        row['centre_id'] = int(row['centre_id'])
        row['num_farmers'] = float(row['num_farmers'])
        row['avg_processing_time_seconds'] = float(row['avg_processing_time_seconds'])
      except (ValueError, TypeError):
        continue
      rows.append(row)
  return rows


def historical_slot_average(centre_id, slot_start, slot_end, day_of_week=None):
  rows = load_historical_data()
  matched = []

  for row in rows:
    if row['centre_id'] != int(centre_id):
      continue
    if row.get('slot_start') != slot_start or row.get('slot_end') != slot_end:
      continue
    if day_of_week is not None:
      try:
        row_day = datetime.strptime(row.get('date', ''), '%Y-%m-%d').weekday()
      except ValueError:
        row_day = None
      if row_day != day_of_week:
        continue
    matched.append(row['num_farmers'])

  if not matched:
    return 0
  return sum(matched) / len(matched)


def classify_load(load_score):
  if load_score <= 40:
    return 'LOW'
  if load_score <= 70:
    return 'MODERATE'
  return 'HIGH'


@app.post('/recommend-slot')
def recommend_slot():
  payload = request.get_json(silent=True) or {}
  centre_id = payload.get('centre_id')
  slots = payload.get('slots', [])
  queue_length = float(payload.get('current_queue_length', 0))
  active_counters = max(float(payload.get('active_counters', 1)), 1)
  preferred_date = payload.get('date')

  if not centre_id or not isinstance(slots, list) or not slots:
    return jsonify({'message': 'centre_id and non-empty slots are required'}), 400

  day_of_week = None
  if preferred_date:
    try:
      day_of_week = datetime.strptime(preferred_date, '%Y-%m-%d').weekday()
    except ValueError:
      day_of_week = None

  scored_slots = []
  for slot in slots:
    booked = float(slot.get('booked_count', 0))
    capacity = max(float(slot.get('max_capacity', 1)), 1)
    slot_start = slot.get('slot_start')
    slot_end = slot.get('slot_end')

    booking_factor = (booked / capacity) * 100

    historical_avg = historical_slot_average(centre_id, slot_start, slot_end, day_of_week)
    hist_factor = min((historical_avg / capacity) * 100, 100)

    queue_factor = min((queue_length / (capacity + 1)) * 100, 100)

    effective_capacity = capacity * active_counters
    capacity_factor = min((booked / effective_capacity) * 100, 100)

    load_score = (
      (0.40 * booking_factor)
      + (0.25 * hist_factor)
      + (0.20 * queue_factor)
      + (0.15 * capacity_factor)
    )

    estimated_wait_minutes = round((queue_length * 3.5) / active_counters + (load_score / 12))

    scored_slots.append(
      {
        'slot_start': slot_start,
        'slot_end': slot_end,
        'load_score': round(load_score, 2),
        'crowd_level': classify_load(load_score),
        'estimated_wait_minutes': max(estimated_wait_minutes, 0),
        'reason': 'Lower predicted queue and faster processing capacity.'
      }
    )

  scored_slots.sort(key=lambda item: item['load_score'])

  recommended = scored_slots[0]
  return jsonify(
    {
      'recommended_slot': recommended,
      'alternatives': scored_slots,
      'explanation': 'Recommendation is based on booking, historical, queue, and processing capacity factors.'
    }
  )


@app.post('/predict-wait')
def predict_wait():
  payload = request.get_json(silent=True) or {}

  farmers_ahead = max(float(payload.get('farmers_ahead', 0)), 0)
  active_counters = max(float(payload.get('active_counters', 1)), 1)
  avg_processing_seconds = max(float(payload.get('avg_processing_seconds', 180)), 1)
  current_queue_length = max(float(payload.get('current_queue_length', farmers_ahead)), 0)
  centre_load = str(payload.get('centre_load', 'LOW')).upper()

  base_wait_minutes = (farmers_ahead * avg_processing_seconds) / active_counters / 60

  load_multiplier = {
    'LOW': 0.9,
    'MODERATE': 1.0,
    'HIGH': 1.2
  }.get(centre_load, 1.0)

  queue_pressure_multiplier = 1 + min(current_queue_length / 200, 0.25)
  estimated_wait_minutes = round(base_wait_minutes * load_multiplier * queue_pressure_multiplier)

  return jsonify(
    {
      'estimated_wait_minutes': max(estimated_wait_minutes, 0),
      'factors': {
        'farmers_ahead': farmers_ahead,
        'active_counters': active_counters,
        'avg_processing_seconds': avg_processing_seconds,
        'load_multiplier': load_multiplier,
        'queue_pressure_multiplier': round(queue_pressure_multiplier, 3)
      }
    }
  )


if __name__ == '__main__':
  app.run(host='0.0.0.0', port=5000, debug=True)
