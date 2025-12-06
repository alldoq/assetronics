defmodule Assetronics.Workflows.Templates do
  @moduledoc """
  Predefined workflow templates for common asset and employee management processes.

  This module provides standardized workflow definitions that can be instantiated
  for specific assets or employees.
  """

  @doc """
  Returns the workflow template for incoming hardware.

  This workflow handles the complete process of receiving, configuring, and deploying
  new hardware assets.
  """
  def incoming_hardware_template do
    %{
      title: "Incoming Hardware Setup",
      workflow_type: "procurement",
      priority: "normal",
      description: "Complete process for receiving, configuring, and deploying new hardware",
      steps: [
        %{
          order: 1,
          name: "Receive Shipment",
          description: "Verify shipment contents match purchase order and check for damage",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Verify tracking number and delivery confirmation
          - Inspect packaging for damage
          - Count items against packing slip
          - Check serial numbers match purchase order
          - Photograph any damage or discrepancies
          - Update asset records with serial numbers
          """
        },
        %{
          order: 2,
          name: "Initial Inspection",
          description: "Perform quality check and inventory verification",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Power on device and verify basic functionality
          - Check for physical defects or cosmetic issues
          - Verify all accessories are included (power adapter, cables, etc.)
          - Document asset details (model, specs, condition)
          - Take photos for asset records
          - Report any issues to vendor
          """
        },
        %{
          order: 3,
          name: "Asset Registration",
          description: "Register asset in inventory system with complete details",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Create asset record with serial number
          - Upload photos and documentation
          - Record purchase details (PO number, cost, date, vendor)
          - Set warranty information and expiration date
          - Assign asset tag/barcode
          - Update inventory counts
          """
        },
        %{
          order: 4,
          name: "Configuration & Setup",
          description: "Install required software and configure for deployment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Install operating system or verify factory image
          - Apply security patches and updates
          - Install required software packages
          - Configure MDM enrollment (Jamf/Intune)
          - Set up disk encryption
          - Configure security settings
          - Install monitoring/antivirus software
          - Create recovery media or backup
          """
        },
        %{
          order: 5,
          name: "Quality Assurance Testing",
          description: "Verify all systems are working correctly before deployment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Test all hardware components (keyboard, trackpad, ports, camera, etc.)
          - Verify network connectivity (Wi-Fi, Ethernet)
          - Test software installations
          - Verify MDM enrollment is successful
          - Check encryption is enabled
          - Confirm security software is active
          - Run diagnostic tests
          """
        },
        %{
          order: 6,
          name: "Assignment & Deployment",
          description: "Assign to employee and prepare for handoff",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Assign asset to specific employee in system
          - Prepare welcome documentation
          - Schedule handoff meeting or shipping
          - Create user account if not auto-provisioned
          - Send setup instructions and credentials
          - Update asset status to 'assigned'
          - Record transaction in audit log
          """
        },
        %{
          order: 7,
          name: "User Onboarding",
          description: "Ensure employee is set up and trained",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Conduct hardware handoff (in-person or remote)
          - Verify employee can log in successfully
          - Provide basic training on device usage
          - Share IT policies and acceptable use guidelines
          - Collect signed acknowledgment of asset receipt
          - Provide support contact information
          - Schedule follow-up check-in
          """
        },
        %{
          order: 8,
          name: "Follow-up & Documentation",
          description: "Complete paperwork and verify successful deployment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Obtain signed asset acknowledgment form
          - Upload signed documents to employee record
          - Send follow-up survey after 1 week
          - Address any reported issues
          - Update asset status to 'in_use'
          - Close procurement workflow
          - Archive all related documentation
          """
        }
      ]
    }
  end

  @doc """
  Returns the workflow template for new employee onboarding.

  This workflow handles the complete IT onboarding process for new staff members,
  from pre-start preparation through their first week.
  """
  def new_employee_onboarding_template do
    %{
      title: "New Employee IT Onboarding",
      workflow_type: "onboarding",
      priority: "high",
      description: "Complete IT setup process for new employee from day -5 to day 7",
      steps: [
        %{
          order: 1,
          name: "Pre-Onboarding Preparation (Day -5)",
          description: "Prepare accounts and equipment before start date",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Verify hiring manager approval and start date
          - Review required software/tools for role
          - Check equipment availability
          - Order any missing hardware
          - Prepare desk/workspace (if on-site)
          - Create onboarding ticket/checklist
          - Notify IT team of upcoming start
          """
        },
        %{
          order: 2,
          name: "Account Provisioning (Day -3)",
          description: "Create user accounts and set up access permissions",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Create email account (Office 365/Google Workspace)
          - Set up SSO/identity provider account (Okta/Azure AD)
          - Provision Slack/Teams account
          - Create VPN credentials
          - Set up multi-factor authentication
          - Assign to appropriate security groups
          - Configure role-based permissions
          - Generate temporary password
          """
        },
        %{
          order: 3,
          name: "Software License Assignment (Day -2)",
          description: "Allocate required software licenses and subscriptions",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Review role-specific software requirements
          - Assign Microsoft 365/Google Workspace license
          - Provision collaboration tools (Slack, Zoom, etc.)
          - Assign specialized software licenses (Adobe, Figma, IDEs, etc.)
          - Set up development environment access (if applicable)
          - Configure access to internal tools/systems
          - Document all assigned licenses
          """
        },
        %{
          order: 4,
          name: "Hardware Setup (Day -1)",
          description: "Configure and prepare hardware for deployment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Assign laptop/desktop to employee
          - Configure device with company image
          - Enroll in MDM (Jamf/Intune)
          - Install required software packages
          - Apply security configurations
          - Test hardware functionality
          - Prepare accessories (mouse, keyboard, dock, etc.)
          - Package for shipping (if remote) or stage at desk
          """
        },
        %{
          order: 5,
          name: "Day 1 - Welcome & Access",
          description: "First day setup and credential handoff",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Greet new employee and provide hardware
          - Share login credentials securely
          - Guide through first-time login and password reset
          - Set up MFA (multi-factor authentication)
          - Verify email access
          - Test VPN connection
          - Provide IT contact information
          - Schedule IT orientation session
          """
        },
        %{
          order: 6,
          name: "Day 1 - IT Orientation",
          description: "Conduct IT systems training and policy review",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Tour of IT systems and tools
          - Review acceptable use policy
          - Explain security best practices
          - Demonstrate password manager usage
          - Show how to request IT support
          - Explain asset care and return policies
          - Provide emergency IT contacts
          - Answer questions and troubleshoot issues
          """
        },
        %{
          order: 7,
          name: "Week 1 - Application Access Setup",
          description: "Grant access to role-specific applications and resources",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Work with manager to identify required systems
          - Provision access to business applications
          - Set up access to shared drives/folders
          - Configure project management tool access
          - Add to relevant distribution lists
          - Set up calendar sharing
          - Configure mobile device (if applicable)
          - Test access to all critical systems
          """
        },
        %{
          order: 8,
          name: "Week 1 - Training & Documentation",
          description: "Provide training materials and ensure understanding",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Share IT knowledge base/wiki access
          - Provide video tutorials for key systems
          - Review data classification and handling
          - Explain backup and recovery procedures
          - Demonstrate remote work setup (if applicable)
          - Share troubleshooting guides
          - Confirm understanding of security protocols
          """
        },
        %{
          order: 9,
          name: "Week 1 - Follow-up & Validation",
          description: "Verify successful onboarding and address any issues",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Schedule check-in meeting
          - Verify all accounts are working
          - Confirm access to all required systems
          - Address any technical issues
          - Collect feedback on onboarding process
          - Update asset assignment records
          - Obtain signed acknowledgment forms
          - Mark onboarding workflow as complete
          """
        }
      ]
    }
  end

  @doc """
  Returns the workflow template for equipment return/offboarding.

  This workflow ensures secure data handling and complete asset recovery when
  an employee departs or returns equipment.
  """
  def equipment_return_template do
    %{
      title: "Equipment Return & Offboarding",
      workflow_type: "offboarding",
      priority: "high",
      description: "Secure process for recovering equipment and removing access",
      steps: [
        %{
          order: 1,
          name: "Schedule Equipment Return",
          description: "Coordinate logistics for equipment recovery",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Contact employee to schedule return
          - Provide return instructions
          - Arrange shipping label (if remote)
          - Set expected return date
          - Create checklist of items to return
          - Send reminder notifications
          """
        },
        %{
          order: 2,
          name: "Data Backup (If Needed)",
          description: "Ensure important data is preserved before wiping",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Verify cloud sync is complete
          - Check for local-only files
          - Backup any critical data per retention policy
          - Transfer ownership of documents
          - Archive email if required
          - Document backup location
          """
        },
        %{
          order: 3,
          name: "Receive & Inspect Equipment",
          description: "Accept returned equipment and assess condition",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Verify all items returned
          - Inspect for physical damage
          - Check accessories (charger, cables, etc.)
          - Document condition with photos
          - Update asset status to 'returned'
          - Report any damage or missing items
          """
        },
        %{
          order: 4,
          name: "Revoke Access & Remove MDM",
          description: "Remove device from management and wipe remotely if needed",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Remove from MDM (Jamf/Intune)
          - Disable device access
          - Revoke certificates
          - Remove from security groups
          - Disable user account
          - Remove MFA devices
          - Log access revocation
          """
        },
        %{
          order: 5,
          name: "Wipe & Reconfigure",
          description: "Securely erase data and prepare for redeployment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Perform factory reset or secure wipe
          - Verify data erasure
          - Reinstall OS or restore to factory image
          - Re-enroll in MDM
          - Apply latest updates
          - Test functionality
          - Update asset status to 'in_stock'
          """
        },
        %{
          order: 6,
          name: "Update Records & Close",
          description: "Finalize documentation and return process",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Update asset assignment to unassigned
          - Record return transaction
          - File condition report
          - Update inventory counts
          - Close support tickets
          - Archive offboarding documentation
          - Mark workflow complete
          """
        }
      ]
    }
  end

  @doc """
  Returns the workflow template for emergency hardware replacement.

  Used when an employee's device fails and needs immediate replacement.
  """
  def emergency_replacement_template do
    %{
      title: "Emergency Hardware Replacement",
      workflow_type: "repair",
      priority: "urgent",
      description: "Fast-track replacement process for failed or damaged equipment",
      steps: [
        %{
          order: 1,
          name: "Assess Situation",
          description: "Determine severity and replacement urgency",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Document the issue/failure
          - Assess business impact
          - Determine if repair is possible
          - Check warranty status
          - Verify available replacement stock
          - Set priority level
          """
        },
        %{
          order: 2,
          name: "Approve Replacement",
          description: "Get necessary approvals for replacement",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Submit replacement request
          - Get manager approval
          - Check budget availability
          - Document approval
          - Notify procurement if purchase needed
          """
        },
        %{
          order: 3,
          name: "Provision Replacement Device",
          description: "Quickly configure replacement hardware",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Pull replacement from stock
          - Quick configuration with essential apps
          - Enroll in MDM
          - Transfer user data if possible
          - Test critical functionality
          - Prepare for handoff
          """
        },
        %{
          order: 4,
          name: "Deploy to User",
          description: "Get replacement device to employee ASAP",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Coordinate urgent delivery/pickup
          - Assist with setup and login
          - Verify access to critical systems
          - Collect failed device if possible
          - Update asset assignments
          - Provide temporary support
          """
        },
        %{
          order: 5,
          name: "Handle Failed Device",
          description: "Process the failed/damaged equipment",
          completed: false,
          assigned_to: nil,
          instructions: """
          - Attempt data recovery if needed
          - Submit warranty claim if applicable
          - Send for repair or disposal
          - Update asset status
          - Document resolution
          - Close incident ticket
          """
        }
      ]
    }
  end

  @doc """
  Creates a workflow from a template with specific parameters.

  ## Parameters
    - template_key: :incoming_hardware | :new_employee | :equipment_return | :emergency_replacement
    - attrs: Map of attributes to override template defaults (employee_id, asset_id, assigned_to, etc.)

  ## Examples
      iex> Templates.from_template(:incoming_hardware, %{asset_id: 123, assigned_to: "it@company.com"})
      %{title: "Incoming Hardware Setup", workflow_type: "procurement", ...}
  """
  def from_template(template_key, attrs \\ %{}) do
    template = case template_key do
      :incoming_hardware -> incoming_hardware_template()
      :new_employee -> new_employee_onboarding_template()
      :equipment_return -> equipment_return_template()
      :emergency_replacement -> emergency_replacement_template()
      _ -> raise ArgumentError, "Unknown template: #{inspect(template_key)}"
    end

    # Merge template with provided attributes
    Map.merge(template, attrs)
  end

  @doc """
  Lists all available workflow templates with metadata.
  """
  def list_templates do
    [
      %{
        key: :incoming_hardware,
        name: "Incoming Hardware Setup",
        type: "procurement",
        description: "Complete process for receiving, configuring, and deploying new hardware",
        estimated_duration_days: 3,
        step_count: 8
      },
      %{
        key: :new_employee,
        name: "New Employee IT Onboarding",
        type: "onboarding",
        description: "Complete IT setup process for new staff members",
        estimated_duration_days: 7,
        step_count: 9
      },
      %{
        key: :equipment_return,
        name: "Equipment Return & Offboarding",
        type: "offboarding",
        description: "Secure process for recovering equipment and removing access",
        estimated_duration_days: 2,
        step_count: 6
      },
      %{
        key: :emergency_replacement,
        name: "Emergency Hardware Replacement",
        type: "repair",
        description: "Fast-track replacement for failed or damaged equipment",
        estimated_duration_days: 1,
        step_count: 5
      }
    ]
  end
end
