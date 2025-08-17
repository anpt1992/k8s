# Product Inventory API

## Stress Testing with wrk

To stress test the API using [wrk](https://github.com/wg/wrk):

1. **Install wrk** (if not already installed):
   ```bash
   sudo apt-get update
   sudo apt-get install wrk
   ```
   Or build from source as described in the [wrk repo](https://github.com/wg/wrk).

2. **CPU-Intensive Test:**
   If you have a `/cpu-burn` endpoint for testing:
   ```bash
   wrk -t4 -c100 -d30s http://localhost:8080/cpu-burn
   ```

3. **Check autoscaling:**
   - Monitor HPA and pods during the test:
     ```bash
     kubectl get hpa -n final-assigment
     kubectl get pods -n final-assigment
     ```

4. **Notes:**
   - Remove or protect any CPU-burn endpoints after testing to avoid accidental resource exhaustion.
