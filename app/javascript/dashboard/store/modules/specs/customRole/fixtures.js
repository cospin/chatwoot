export const customRoleList = [
  {
    id: 1,
    name: 'Super Custom Role',
    description: 'Role with all available custom role permissions',
    permissions: [
      'conversation_participating_manage',
      'conversation_unassigned_manage',
      'conversation_manage',
      'contact_manage',
      'report_manage',
      'knowledge_base_manage',
    ],
    created_at: '2024-09-04T05:30:22.282Z',
    updated_at: '2024-09-05T09:21:02.844Z',
  },
  {
    id: 2,
    name: 'Conversation Manager Role',
    description: 'Role for managing all aspects of conversations',
    permissions: [
      'conversation_unassigned_manage',
      'conversation_participating_manage',
      'conversation_manage',
    ],
    created_at: '2024-09-05T09:21:38.692Z',
    updated_at: '2024-09-05T09:21:38.692Z',
  },
  {
    id: 3,
    name: 'Participating Agent Role',
    description: 'Role for agents participating in conversations',
    permissions: ['conversation_participating_manage'],
    created_at: '2024-09-06T08:03:14.550Z',
    updated_at: '2024-09-06T08:03:14.550Z',
  },
  {
    id: 4,
    name: 'Contact Manager Role',
    description: 'Role for managing contacts only',
    permissions: ['contact_manage'],
    created_at: '2024-09-06T08:15:56.877Z',
    updated_at: '2024-09-06T09:53:28.103Z',
  },
  {
    id: 5,
    name: 'Report Analyst Role',
    description: 'Role for accessing and managing reports',
    permissions: ['report_manage'],
    created_at: '2024-09-06T09:53:58.277Z',
    updated_at: '2024-09-06T09:53:58.277Z',
  },
  {
    id: 6,
    name: 'Knowledge Base Editor Role',
    description: 'Role for managing the knowledge base',
    permissions: ['knowledge_base_manage'],
    created_at: '2024-09-06T09:54:27.649Z',
    updated_at: '2024-09-06T09:54:27.649Z',
  },
  {
    id: 7,
    name: 'Unassigned Queue Manager Role',
    description: 'Role for managing unassigned conversations',
    permissions: ['conversation_unassigned_manage'],
    created_at: '2024-09-06T09:55:00.503Z',
    updated_at: '2024-09-06T09:55:00.503Z',
  },
  {
    id: 8,
    name: 'Basic Conversation Handler Role',
    description: 'Role for basic conversation management',
    permissions: ['conversation_manage'],
    created_at: '2024-09-06T09:55:19.519Z',
    updated_at: '2024-09-06T09:55:19.519Z',
  },
];
