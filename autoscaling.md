### **🔹 Understanding Auto Scaling Policies Clearly**
Auto Scaling is controlled by **scaling policies** that determine when to **add** or **remove** instances based on CloudWatch alarms.

Let’s break it down so you fully understand **what happens when you trigger CPU stress**.

---

### **Auto Scaling Configuration**
From what we've set up, **Auto Scaling Group (ASG)**:
- **Min Instances:** `1`  
- **Max Instances:** `4`  
- **Desired Capacity:** `2`  
- **Scaling Policies:**
  - **Scale-Out Policy (Increase Instances)**  
    🔹 If **CPU > 30%** for **1 evaluation period (60 sec)** → **Launch a new instance**
  - **Scale-In Policy (Reduce Instances)**  
    🔹 If **CPU < 20%** for **2 evaluation periods (120 sec)** → **Terminate an instance**

---

### **What Happens When Running `stress --cpu 4 --timeout 120` on the default instance?**

```bash
stress --cpu 4 --timeout 120
```
1️⃣ **Step 1: CPU Usage Rises**  
   - The `stress --cpu 4 --timeout 120` command **simulates high CPU load** for **120 seconds**.
   - The CloudWatch alarm **measures CPU utilization every 60 seconds**.

2️⃣ **Step 2: CloudWatch Triggers Scale-Out**  
   - If **CPU > 30%**, the `"ScaleOutAlarm"` changes to `"ALARM"`.
   - CloudWatch **notifies Auto Scaling** to launch a new instance.
   - **A new instance is created** (appears in EC2 console within a few minutes).

3️⃣ **Step 3: CPU Load Returns to Normal**  
   - After 120 seconds, the stress test stops, and CPU usage **gradually decreases**.
   - The `"ScaleOutAlarm"` returns to `"OK"`.

4️⃣ **Step 4: CloudWatch Triggers Scale-In**  
   - If CPU drops **below 20% for 2 evaluation periods (120 sec)**:
   - The `"ScaleInAlarm"` enters `"ALARM"` state.
   - Auto Scaling **removes an instance** (moves to `Terminating` state).
   - **It gradually disappears from the EC2 instance list**.

---

### **🔹 Expected Outcome from the Test**
🔹 **If you run `stress --cpu 4 --timeout 120` on 1 instance:**

✔️ CPU **rises above 30%** → Auto Scaling **adds a new instance**  
✔️ After 120 sec, stress stops → CPU **drops below 20%**  
✔️ Auto Scaling waits **2 evaluation periods (120 sec)** before **removing an instance**  

---

### **How to Monitor Everything in Real-Time**
While testing, monitor these:

✔️ **Check CloudWatch Alarm State:**
```bash
aws cloudwatch describe-alarms --region eu-west-1 --query "MetricAlarms[*].[AlarmName,StateValue]"
```
- `"ALARM"` on `"ScaleOutAlarm"` → Scaling **adds** an instance.
- `"ALARM"` on `"ScaleInAlarm"` → Scaling **removes** an instance.

✔️ **Check Auto Scaling Instances:**
```bash
aws autoscaling describe-auto-scaling-instances --region eu-west-1
```
- **New instance appears during Scale-Out**.
- **Instance moves to `Terminating` state during Scale-In**.

---

### **Summary**
✅ **Auto Scaling adds instances when CPU rises above 30%.**  
✅ **It removes instances when CPU drops below 20%.**  
✅ **Scaling takes a few minutes to process.**  

Try triggering the **stress test on your instance to understand it**, monitor the behavior and confirm it works.


---

#### **1️⃣ Run the Stress Test with Higher CPU Load**
- **If your instance type is `t2.micro`, it has only 1 vCPU**.  
  - Use **`--cpu 1` on multiple instances at the same time**.
run:  
  ```bash
  stress --cpu 1 --timeout 180
  ```

- **If your instance type has more vCPUs (`t3.medium`, `c5.large`, etc.)**, you can run:  
  ```bash
  stress --cpu 16 --timeout 180
  ```
  or  
  ```bash
  stress --cpu 24 --timeout 180
  ```
  - This will **saturate the CPU usage** for **3 minutes**.

---

### **Expected Observations**
✔️ **Health Check Behavior**  
   - If CPU is **fully maxed out**, **instances may fail ALB health checks**.
   - Instances with high CPU usage **might show as "Unhealthy"** in **EC2 -> Target Groups**.
   - ALB may **stop routing traffic** to unhealthy instances.

✔️ **Auto Scaling Reaction**  
   - CloudWatch should detect **CPU > 30%** and **keep adding instances** until the max limit (`max_size`) is reached.
   - Check the **number of instances Auto Scaling creates** using:
     ```bash
     aws autoscaling describe-auto-scaling-instances --region eu-west-1
     ```
   - Monitor CloudWatch alarms to see `"ScaleOutAlarm"` triggering:
     ```bash
     aws cloudwatch describe-alarms --region eu-west-1 --query "MetricAlarms[*].[AlarmName,StateValue]"
     ```

---

### **What to Do After the Test**
After you finish testing:
1️⃣ **Stop the Stress Test**  
   ```bash
   sudo killall stress
   ```

2️⃣ **Monitor Scale-In**  
   - Auto Scaling will **start removing instances** if CPU drops below 20%.
   - Check if instances **gradually terminate**:
     ```bash
     aws autoscaling describe-auto-scaling-instances --region eu-west-1
     ```

---

### **Summary**
✅ **Increasing CPU stress tests max Auto Scaling behavior.**  
✅ **ALB health checks may mark instances "Unhealthy" if overloaded.**  
✅ **Auto Scaling will keep adding instances until max capacity is reached.**  

