import requests
import sys

def test_health_check(base_url):
    response = requests.get(f"{base_url}/gtg")
    print(f"/gtg: {response.text.strip()}")

def test_health_check_details(base_url):
    response = requests.get(f"{base_url}/gtg/details")
    print(f"/gtg/details: {response.status_code} - {response.json()}")

def test_add_candidate(base_url, candidate_name, party="ind"):
    response = requests.post(f"{base_url}/candidate/{candidate_name}?party={party}")
    print(f"/candidate/{candidate_name} (POST): {response.status_code} - {response.json()}")

def test_get_candidate(base_url, candidate_name):
    response = requests.get(f"{base_url}/candidate/{candidate_name}")
    print(f"/candidate/{candidate_name} (GET): {response.status_code} - {response.json()}")

def test_get_all_candidates(base_url):
    response = requests.get(f"{base_url}/candidates")
    print(f"/candidates (GET): {response.status_code} - {response.json()}")

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test_candidates.py <base_url>")
        sys.exit(1)

    base_url = sys.argv[1]

    test_health_check(base_url)
    test_health_check_details(base_url)

    # Add a candidate for testing
    test_add_candidate(base_url, "John Doe", party="dem")

    # Test getting a specific candidate
    test_get_candidate(base_url, "John Doe")

    # Test getting all candidates
    test_get_all_candidates(base_url)
