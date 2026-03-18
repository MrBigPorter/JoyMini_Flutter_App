import {
  Body,
  Controller,
  Post,
  UseGuards,
  Delete,
  Param,
  Get,
  Query,
  BadRequestException,
} from '@nestjs/common';
import {
  ApiBearerAuth,
  ApiOperation,
  ApiResponse,
  ApiTags,
} from '@nestjs/swagger';
import { JwtAuthGuard } from '@api/common/jwt/jwt.guard'; // 确保路径正确
import { ChatGroupService } from '@api/common/chat/chat-group.service';
import {
  KickMemberDto,
  KickMemberResDto,
  MuteMemberDto,
  MuteMemberResDto,
  TransferOwnerDto,
  TransferOwnerResDto,
  UpdateGroupInfoDto,
  UpdateGroupResDto,
  SetAdminDto,
  SetAdminResDto,
  LeaveGroupResDto,
  DisbandGroupResDto,
  HandleGroupJoinDto,
  GroupJoinRequestItemDto,
  ApplyToGroupDto,
  ApplyToGroupResDto,
  GroupSearchResultDto,
} from '@api/common/chat/dto/group/group-manage.dto';
import { CurrentUserId } from '@api/common/decorators/user.decorator';
import { plainToInstance } from 'class-transformer'; // 确保路径正确

@ApiTags('Chat Group Management (v6.0)')
@ApiBearerAuth()
@UseGuards(JwtAuthGuard)
@Controller('chat/group')
export class ChatGroupController {
  constructor(private readonly groupService: ChatGroupService) {}

  @Post('kick')
  @ApiOperation({ summary: 'Kick a member from the group (Admins/Owner only)' })
  @ApiResponse({ status: 200, type: KickMemberResDto })
  async kickMember(
    @CurrentUserId() userId: string,
    @Body() dto: KickMemberDto,
  ): Promise<KickMemberResDto> {
    return this.groupService.kickMember(userId, dto);
  }

  @Post('mute')
  @ApiOperation({ summary: 'Mute/Unmute a member (Admins/Owner only)' })
  @ApiResponse({ status: 200, type: MuteMemberResDto })
  async muteMember(
    @CurrentUserId() userId: string,
    @Body() dto: MuteMemberDto,
  ): Promise<MuteMemberResDto> {
    return this.groupService.muteMember(userId, dto);
  }

  @Post('update')
  @ApiOperation({ summary: 'Update group info/settings (Admins/Owner only)' })
  @ApiResponse({ status: 200, type: UpdateGroupResDto })
  async updateGroup(
    @CurrentUserId() userId: string,
    @Body() dto: UpdateGroupInfoDto,
  ): Promise<UpdateGroupResDto> {
    return this.groupService.updateGroupInfo(userId, dto);
  }

  @Post('transfer-owner')
  @ApiOperation({ summary: 'Transfer group ownership (Owner only)' })
  @ApiResponse({ status: 200, type: TransferOwnerResDto })
  async transferOwner(
    @CurrentUserId() userId: string,
    @Body() dto: TransferOwnerDto,
  ): Promise<TransferOwnerResDto> {
    return this.groupService.transferOwner(userId, dto);
  }

  @Post('admin')
  @ApiOperation({ summary: 'Promote/Demote an admin (Owner only)' })
  @ApiResponse({ status: 200, type: SetAdminResDto })
  async setAdmin(
    @CurrentUserId() userId: string,
    @Body() dto: SetAdminDto,
  ): Promise<SetAdminResDto> {
    return this.groupService.setAdmin(userId, dto);
  }

  @Delete('leave/:conversationId')
  @ApiOperation({ summary: 'Leave a group (Member/Admin only)' })
  @ApiResponse({ status: 200, type: LeaveGroupResDto })
  async leaveGroup(
    @CurrentUserId() userId: string,
    @Param('conversationId') conversationId: string,
  ): Promise<LeaveGroupResDto> {
    return this.groupService.leaveGroup(userId, conversationId);
  }

  @Delete('disband/:conversationId')
  @ApiOperation({ summary: 'Disband a group (Owner only)' })
  @ApiResponse({ status: 200, type: DisbandGroupResDto })
  async disbandGroup(
    @CurrentUserId() userId: string,
    @Param('conversationId') conversationId: string,
  ): Promise<DisbandGroupResDto> {
    return this.groupService.disbandGroup(userId, conversationId);
  }

  // =================================================================
  // [NEW] 1. 申请加入群组 (User Action)
  // =================================================================
  @Post('apply')
  @ApiOperation({ summary: 'Apply to join a group (Stranger only)' })
  @ApiResponse({ status: 200, type: ApplyToGroupResDto })
  async applyToGroup(
    @CurrentUserId() userId: string,
    @Body() dto: ApplyToGroupDto,
  ) {
    return this.groupService.applyToGroup(
      userId,
      dto.conversationId,
      dto.reason,
    );
  }

  // =================================================================
  // [NEW] 2. 获取待处理列表 (Admin Action)
  // =================================================================
  @Get('requests/:conversationId')
  @ApiOperation({ summary: 'Get pending join requests (Admin/Owner only)' })
  @ApiResponse({ status: 200, type: [GroupJoinRequestItemDto] })
  async getJoinRequests(
    @CurrentUserId() userId: string,
    @Param('conversationId') conversationId: string,
  ) {
    const res = await this.groupService.getJoinRequests(userId, conversationId);
    return plainToInstance(GroupJoinRequestItemDto, res);
  }

  // =================================================================
  // [NEW] 3. 审批申请 (Admin Action)
  // =================================================================
  @Post('request/handle')
  @ApiOperation({
    summary: 'Accept or reject a join request (Admin/Owner only)',
  })
  @ApiResponse({ status: 200 })
  async handleRequest(
    @CurrentUserId() userId: string,
    @Body() dto: HandleGroupJoinDto,
  ) {
    return this.groupService.handleJoinRequest(
      userId,
      dto.requestId,
      dto.action,
    );
  }

  /**
   * Search for groups by keyword (for joining new groups)
   * @param userId
   * @param keyword
   */
  @Get('/search')
  @ApiResponse({ status: 200, type: [GroupSearchResultDto] }) // Swagger 文档
  async searchGroups(
    @CurrentUserId() userId: string,
    @Query('keyword') keyword: string,
  ) {
    if (!keyword) throw new BadRequestException('Keyword is required');
    return this.groupService.searchGroups(userId, keyword);
  }
}
